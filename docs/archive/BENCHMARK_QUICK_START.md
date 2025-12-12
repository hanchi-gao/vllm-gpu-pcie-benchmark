# vLLM 基准测试快速开始

## 🚀 问题解决：上下文长度限制

**错误**：
```
This model's maximum context length is 896 tokens. However, your request has 1024 input tokens.
```

**原因**：gpt-oss-120b 模型的最大上下文长度是 **896 tokens**

**解决**：确保 `input_len + output_len < 896`

---

## 📋 快速使用

### 1. 启动容器

```bash
# 启动两个容器
./host_scripts/start_bench_containers.sh

# 查看状态
./host_scripts/start_bench_containers.sh ps
```

### 2. 启动 vLLM 服务器

**终端 1**：
```bash
# 进入服务器容器
./host_scripts/start_bench_containers.sh server

# 启动服务器
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --dtype bfloat16 \
  --max-model-len 896 \
  --gpu-memory-utilization 0.8 \
  --enforce-eager
```

### 3. 运行基准测试

**终端 2**：
```bash
# 进入客户端容器
./host_scripts/start_bench_containers.sh client

# 使用脚本运行测试
/root/container_scripts/run_benchmark.sh
```

---

## 🎯 使用脚本的优势

✅ **自动配置** - 默认使用安全的 token 长度
✅ **灵活参数** - 支持命令行参数和环境变量
✅ **自动保存** - 结果保存到 `/root/bench_results/`
✅ **错误检查** - 自动检查服务器连接

---

## 📝 脚本使用示例

### 示例 1: 使用默认配置
```bash
/root/container_scripts/run_benchmark.sh
```

**默认配置**：
- 输入长度: 256 tokens
- 输出长度: 128 tokens
- 并发范围: 1-32
- 每次测试: 20 个请求

### 示例 2: 只测试特定并发数
```bash
# 只测试 8 并发
/root/container_scripts/run_benchmark.sh --single 8

# 只测试 16 并发
/root/container_scripts/run_benchmark.sh --single 16
```

### 示例 3: 自定义并发范围
```bash
# 测试 1-16 并发，步长 2
/root/container_scripts/run_benchmark.sh \
  --min-concurrency 1 \
  --max-concurrency 16 \
  --step 2
```

### 示例 4: 自定义输入输出长度
```bash
# 较短的输入输出
/root/container_scripts/run_benchmark.sh \
  --input-len 128 \
  --output-len 64

# 较长的输入输出（接近上限）
/root/container_scripts/run_benchmark.sh \
  --input-len 512 \
  --output-len 256
```

### 示例 5: 快速测试
```bash
# 单并发，少量请求，短输入输出
/root/container_scripts/run_benchmark.sh \
  --single 4 \
  --num-prompts 10 \
  --input-len 128 \
  --output-len 64
```

### 示例 6: 完整测试
```bash
# 全面测试 1-32 并发
/root/container_scripts/run_benchmark.sh \
  --min-concurrency 1 \
  --max-concurrency 32 \
  --step 1 \
  --num-prompts 20 \
  --input-len 256 \
  --output-len 128
```

---

## 🔧 手动运行 vllm bench（不使用脚本）

如果你想完全手动控制：

```bash
# 单次测试
vllm bench serve \
  --backend openai \
  --base-url http://vllm-server:8000 \
  --endpoint /v1/completions \
  --model openai/gpt-oss-120b \
  --num-prompts 20 \
  --max-concurrency 8 \
  --dataset-name random \
  --random-input-len 256 \
  --random-output-len 128 \
  --save-result

# 保存结果
cp results.json /root/bench_results/results_8.json
```

---

## 📊 Token 长度配置建议

### gpt-oss-120b (最大 896 tokens)

| 场景 | Input | Output | 总计 | 适用 |
|------|-------|--------|------|------|
| **安全配置** | 256 | 128 | 384 | ✅ 推荐 |
| **平衡配置** | 384 | 256 | 640 | ✅ 较好 |
| **高负载** | 512 | 256 | 768 | ⚠️ 接近上限 |
| **极限** | 600 | 256 | 856 | ⚠️ 风险 |
| **超限** | 512 | 512 | 1024 | ❌ 失败 |

**推荐**：
- 开发测试: `input=128, output=64`
- 常规测试: `input=256, output=128` (默认)
- 压力测试: `input=384, output=256`

---

## 📁 查看结果

### 在容器中
```bash
# 列出所有结果
ls -lh /root/bench_results/

# 查看最新结果
ls -lt /root/bench_results/ | head -5

# 查看特定结果
cat /root/bench_results/results_8_*.json

# 美化输出
python3 -m json.tool /root/bench_results/results_8_*.json
```

### 在主机上
```bash
# 列出结果
ls -lh bench_results/

# 查看结果
cat bench_results/results_8_*.json

# 美化输出
python3 -m json.tool bench_results/results_8_*.json
```

---

## 🔍 分析结果

### 提取关键指标

```bash
# 在容器或主机上运行
python3 << 'EOF'
import json
import glob

# 找到所有结果文件
files = sorted(glob.glob('/root/bench_results/results_*.json'))

print("=" * 70)
print(f"{'并发数':<10} {'吞吐量':<15} {'平均延迟':<15} {'TTFT':<15}")
print("=" * 70)

for file in files:
    # 从文件名提取并发数
    concurrency = file.split('_')[1]

    with open(file) as f:
        data = json.load(f)

    # 提取指标（根据实际 vllm bench 输出格式调整）
    throughput = data.get('throughput', 'N/A')
    latency = data.get('mean_latency', 'N/A')
    ttft = data.get('mean_ttft', 'N/A')

    print(f"{concurrency:<10} {throughput:<15} {latency:<15} {ttft:<15}")

print("=" * 70)
EOF
```

---

## ⚙️ 环境变量配置

你可以通过环境变量设置默认值：

```bash
# 在客户端容器中
export VLLM_SERVER_URL=http://vllm-server:8000
export MODEL=openai/gpt-oss-120b
export NUM_PROMPTS=20
export INPUT_LEN=256
export OUTPUT_LEN=128

# 然后直接运行脚本
/root/container_scripts/run_benchmark.sh
```

或者创建配置文件：

```bash
# 创建配置
cat > /root/bench_config.sh << 'EOF'
export VLLM_SERVER_URL=http://vllm-server:8000
export MODEL=openai/gpt-oss-120b
export NUM_PROMPTS=20
export INPUT_LEN=256
export OUTPUT_LEN=128
EOF

# 加载配置并运行
source /root/bench_config.sh
/root/container_scripts/run_benchmark.sh
```

---

## 💡 提示和技巧

### 1. 测试前检查服务器
```bash
curl http://vllm-server:8000/health
curl http://vllm-server:8000/v1/models
```

### 2. 监控服务器日志
```bash
# 在主机上另开终端
./host_scripts/start_bench_containers.sh logs-server
```

### 3. 分批测试
```bash
# 低并发
/root/container_scripts/run_benchmark.sh --min-concurrency 1 --max-concurrency 8

# 中等并发
/root/container_scripts/run_benchmark.sh --min-concurrency 8 --max-concurrency 16

# 高并发
/root/container_scripts/run_benchmark.sh --min-concurrency 16 --max-concurrency 32
```

### 4. 清理旧结果
```bash
# 备份结果
mkdir -p /root/bench_results/archive
mv /root/bench_results/results_*.json /root/bench_results/archive/

# 或删除
rm /root/bench_results/results_*.json
```

---

## 🎉 总结

使用新的基准测试脚本：

✅ **自动处理 token 长度** - 默认安全配置 (256+128)
✅ **灵活的参数** - 支持各种测试场景
✅ **自动保存结果** - 带时间戳的结果文件
✅ **服务器检查** - 测试前验证连接
✅ **易于使用** - 简单的命令行界面

**现在可以安全地运行基准测试了！** 🚀
