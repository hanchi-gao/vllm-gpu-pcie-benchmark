# Docker Compose 手动基准测试指南

两个独立容器，可以手动进入执行命令和修改参数。

## 🏗️ 架构

```
┌─────────────────────────────────────────┐
│    vllm-bench-client (客户端容器)        │
│    - 手动进入                            │
│    - 运行 vllm bench serve              │
│    - 保存结果到 /root/bench_results     │
└─────────────┬───────────────────────────┘
              │ HTTP (vllm-network)
              │
┌─────────────▼───────────────────────────┐
│    vllm-server (服务器容器)              │
│    - 手动进入                            │
│    - 运行 vllm serve                    │
│    - 端口: 8000                         │
└─────────────────────────────────────────┘
```

## 🚀 快速开始

### 1. 启动两个容器

```bash
# 启动容器（后台运行）
docker compose -f docker-compose.bench.yml up -d

# 查看状态
docker compose -f docker-compose.bench.yml ps
```

输出：
```
NAME                IMAGE                                       STATUS
vllm-server         rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006   Up
vllm-bench-client   rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006   Up
```

---

## 📋 使用流程

### 终端 1: 启动 vLLM 服务器

```bash
# 进入服务器容器
docker exec -it vllm-server bash

# 启动 vLLM 服务（根据需要修改参数）
vllm serve openai/gpt-oss-120b \
  --host 0.0.0.0 \
  --port 8000 \
  --dtype bfloat16 \
  --tensor-parallel-size 4 \
  --max-model-len 1024 \
  --gpu-memory-utilization 0.8 \
  --enforce-eager
```

**或者使用 Python 模块方式**：
```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model openai/gpt-oss-120b \
  --host 0.0.0.0 \
  --port 8000 \
  --dtype bfloat16 \
  --tensor-parallel-size 4 \
  --max-model-len 1024 \
  --gpu-memory-utilization 0.8 \
  --enforce-eager \
  --disable-log-stats
```

### 终端 2: 运行基准测试

```bash
# 进入客户端容器
docker exec -it vllm-bench-client bash

# 运行基准测试
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 32 \
  --max-concurrency 32 \
  --dataset-name random \
  --save-result
```

---

## 🎯 完整测试示例

### 示例 1: 测试不同并发数

**终端 1 - 服务器**：
```bash
docker exec -it vllm-server bash

# 启动服务器（保持运行）
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --enforce-eager
```

**终端 2 - 客户端**：
```bash
docker exec -it vllm-bench-client bash

# 测试 1 并发
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 20 \
  --max-concurrency 1

# 测试 8 并发
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 20 \
  --max-concurrency 8

# 测试 16 并发
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 20 \
  --max-concurrency 16

# 测试 32 并发
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 32 \
  --max-concurrency 32 \
  --save-result
```

---

### 示例 2: 使用脚本自动化测试

在客户端容器中创建测试脚本：

```bash
docker exec -it vllm-bench-client bash

# 创建测试脚本
cat > /root/run_bench_tests.sh << 'EOF'
#!/bin/bash

SERVER_URL="http://vllm-server:8000"
MODEL="openai/gpt-oss-120b"
NUM_PROMPTS=20

echo "Testing different concurrency levels..."

for concurrency in 1 2 4 8 16 32; do
    echo "=========================================="
    echo "Testing concurrency: $concurrency"
    echo "=========================================="

    vllm bench serve \
        --backend openai \
        --base-url $SERVER_URL \
        --endpoint /v1/completions \
        --model $MODEL \
        --num-prompts $NUM_PROMPTS \
        --max-concurrency $concurrency \
        --save-result

    # 保存结果
    if [ -f "results.json" ]; then
        mv results.json /root/bench_results/results_${concurrency}.json
    fi

    echo
    sleep 5
done

echo "All tests completed!"
echo "Results saved to /root/bench_results/"
EOF

chmod +x /root/run_bench_tests.sh

# 运行测试
/root/run_bench_tests.sh
```

---

## 📊 保存和查看结果

### 手动保存结果

在客户端容器中：
```bash
# vllm bench 会生成 results.json
# 复制到持久化目录
cp results.json /root/bench_results/gpt-oss-120b_4gpu_32concurrency.json

# 或者带时间戳
cp results.json /root/bench_results/test_$(date +%Y%m%d_%H%M%S).json
```

### 在主机上查看结果

```bash
# 查看所有结果
ls -lh bench_results/

# 查看特定结果
cat bench_results/gpt-oss-120b_4gpu_32concurrency.json

# 美化输出
python3 -m json.tool bench_results/gpt-oss-120b_4gpu_32concurrency.json
```

---

## 🔧 常用操作

### 启动和停止容器

```bash
# 启动容器
docker compose -f docker-compose.bench.yml up -d

# 停止容器
docker compose -f docker-compose.bench.yml stop

# 重启容器
docker compose -f docker-compose.bench.yml restart

# 完全删除容器
docker compose -f docker-compose.bench.yml down
```

### 进入容器

```bash
# 进入服务器容器
docker exec -it vllm-server bash

# 进入客户端容器
docker exec -it vllm-bench-client bash
```

### 查看日志

```bash
# 查看服务器容器日志
docker logs -f vllm-server

# 查看客户端容器日志
docker logs -f vllm-bench-client
```

### 检查网络连接

在客户端容器中：
```bash
# 检查服务器健康状态
curl http://vllm-server:8000/health

# 测试 API 端点
curl http://vllm-server:8000/v1/models
```

---

## 📝 vllm serve 常用参数

### 基础参数
```bash
vllm serve <model_name> \
  --host 0.0.0.0 \              # 监听所有网络接口
  --port 8000 \                 # 端口号
  --dtype bfloat16 \            # 数据类型
  --tensor-parallel-size 4 \    # GPU 数量
  --max-model-len 1024 \        # 最大序列长度
  --gpu-memory-utilization 0.8  # GPU 内存使用率
```

### 必需参数（AMD GPU）
```bash
--enforce-eager               # 禁用 CUDA graphs（gfx1201 必需）
```

### 可选优化参数
```bash
--disable-log-stats          # 禁用统计日志
--max-num-seqs 256           # 最大批处理序列数
--max-num-batched-tokens 8192  # 最大批处理 token 数
```

---

## 📝 vllm bench serve 常用参数

### 基础参数
```bash
vllm bench serve \
  --backend openai \                    # 后端类型
  --base-url http://vllm-server:8000 \  # 服务器地址
  --endpoint /v1/completions \          # API 端点
  --model <model_name> \                # 模型名称
  --num-prompts 32 \                    # 请求总数
  --max-concurrency 32                  # 最大并发数
```

### 数据集参数
```bash
--dataset-name random \       # 使用随机数据集
--random-input-len 128 \      # 随机输入长度
--random-output-len 128       # 随机输出长度

# 或使用真实数据集
--dataset-name sharegpt \     # 使用 ShareGPT 数据集
--dataset-path ./sharegpt.json
```

### 输出参数
```bash
--save-result                 # 保存结果到 results.json
--result-dir /path/to/dir     # 指定结果目录
--result-filename custom.json # 自定义结果文件名
```

---

## 🆚 vllm serve vs python3 -m vllm.entrypoints.openai.api_server

两种方式功能相同，选择任一即可：

### 方式 1: vllm serve（简洁）
```bash
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --enforce-eager
```

### 方式 2: Python 模块（详细）
```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model openai/gpt-oss-120b \
  --host 0.0.0.0 \
  --port 8000 \
  --tensor-parallel-size 4 \
  --enforce-eager
```

---

## 💡 提示和技巧

### 1. 后台运行服务器
```bash
# 在服务器容器中
nohup vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --enforce-eager \
  > /root/bench_results/server.log 2>&1 &

# 检查进程
ps aux | grep vllm
```

### 2. 监控 GPU 使用
```bash
# 在服务器容器中
watch -n 1 rocm-smi
```

### 3. 批量测试脚本
```bash
# 在客户端容器中
for i in 1 2 4 8 16 32; do
  echo "Testing concurrency: $i"
  vllm bench serve \
    --backend openai \
    --base-url http://vllm-server:8000 \
    --endpoint /v1/completions \
    --model openai/gpt-oss-120b \
    --num-prompts 20 \
    --max-concurrency $i \
    --save-result

  mv results.json /root/bench_results/results_${i}.json
  sleep 5
done
```

### 4. 清理和重启
```bash
# 主机上
docker compose -f docker-compose.bench.yml restart

# 或者完全重建
docker compose -f docker-compose.bench.yml down
docker compose -f docker-compose.bench.yml up -d
```

---

## 🎉 总结

使用 Docker Compose 手动模式的优势：

✅ **完全控制**: 手动启动服务器和测试
✅ **灵活调整**: 随时修改参数和配置
✅ **独立容器**: 服务器和客户端完全隔离
✅ **持久化结果**: 结果保存到主机 `bench_results/` 目录
✅ **网络互通**: 容器间通过 `vllm-network` 通信
✅ **多次测试**: 可以运行多轮测试而不重启服务器

**现在可以完全手动控制基准测试流程了！** 🚀
