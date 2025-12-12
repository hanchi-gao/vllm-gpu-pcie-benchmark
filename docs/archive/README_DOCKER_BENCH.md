# vLLM Docker Compose 基准测试

使用 Docker Compose 部署 vLLM 服务器和客户端进行性能测试。

## 📁 文件结构

```
vllm_t/
├── docker-compose.bench.yml          # Docker Compose 配置
├── .env.bench                         # 环境变量配置
├── container_scripts/
│   └── run_benchmark.sh              # 基准测试脚本
├── host_scripts/
│   └── start_bench_containers.sh     # 容器管理脚本
├── bench_results/                     # 测试结果目录
├── README_DOCKER_BENCH.md            # 本文档
├── DOCKER_COMPOSE_MANUAL.md          # 详细使用手册
└── BENCHMARK_QUICK_START.md          # 快速开始指南
```

---

## 🚀 快速开始

### 1. 启动容器

```bash
./host_scripts/start_bench_containers.sh
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
  --max-model-len 4096 \
  --gpu-memory-utilization 0.8 \
  --enforce-eager
```

### 3. 运行基准测试

**终端 2**：
```bash
# 进入客户端容器
./host_scripts/start_bench_containers.sh client

# 运行测试
/root/container_scripts/run_benchmark.sh
```

---

## 📋 常用命令

### 容器管理

```bash
# 启动容器
./host_scripts/start_bench_containers.sh

# 进入服务器容器
./host_scripts/start_bench_containers.sh server

# 进入客户端容器
./host_scripts/start_bench_containers.sh client

# 查看容器状态
./host_scripts/start_bench_containers.sh ps

# 查看日志
./host_scripts/start_bench_containers.sh logs-server
./host_scripts/start_bench_containers.sh logs-client

# 停止容器
./host_scripts/start_bench_containers.sh stop

# 删除容器
./host_scripts/start_bench_containers.sh down
```

---

## 🎯 基准测试示例

### 默认测试（推荐）
```bash
/root/container_scripts/run_benchmark.sh
```

### 测试单个并发数
```bash
/root/container_scripts/run_benchmark.sh --single 8
```

### 自定义并发范围
```bash
/root/container_scripts/run_benchmark.sh \
  --min-concurrency 1 \
  --max-concurrency 16 \
  --step 2
```

### 自定义输入输出长度
```bash
/root/container_scripts/run_benchmark.sh \
  --input-len 512 \
  --output-len 256
```

---

## ⚙️ 配置文件

### .env.bench

当前配置：
```bash
MODEL_NAME=openai/gpt-oss-120b
DTYPE=bfloat16
GPUS=4
MAX_LEN=1024
GPU_UTIL=0.8
MIN_CLIENTS=1
MAX_CLIENTS=32
STEP=1
DEBUG=false
```

**注意**：这些环境变量仅供参考，实际使用时需要在容器内手动指定参数。

---

## 📊 查看结果

### 在主机上
```bash
# 列出结果
ls -lh bench_results/

# 查看结果
cat bench_results/results_*.json

# 美化输出
python3 -m json.tool bench_results/results_8_*.json
```

---

## 📚 详细文档

- **[DOCKER_COMPOSE_MANUAL.md](DOCKER_COMPOSE_MANUAL.md)** - 完整使用手册
- **[BENCHMARK_QUICK_START.md](BENCHMARK_QUICK_START.md)** - 快速开始和故障排查

---

## 🏗️ 架构

```
┌─────────────────────────────────────────┐
│    vllm-bench-client                    │
│    - 运行基准测试                        │
│    - 发送并发请求                        │
│    - 保存结果                            │
└─────────────┬───────────────────────────┘
              │ HTTP (vllm-network)
              │
┌─────────────▼───────────────────────────┐
│    vllm-server                          │
│    - vLLM API 服务器                     │
│    - OpenAI 兼容 API                    │
│    - 端口: 8000                         │
└─────────────────────────────────────────┘
```

---

## ⚠️ 重要提示

### 上下文长度限制

`openai/gpt-oss-120b` 模型的上下文长度取决于你启动服务器时设置的 `--max-model-len`。

**推荐配置**：
```bash
--max-model-len 4096    # 推荐，平衡性能和内存
```

**测试时的 token 配置**：
- 确保 `input_len + output_len < max_model_len`
- 默认配置：`input=256, output=128` (安全)
- 高负载配置：`input=1024, output=512`

---

## 🎉 开始使用

1. ✅ 启动容器
2. ✅ 在服务器容器中启动 vLLM
3. ✅ 在客户端容器中运行基准测试
4. ✅ 查看结果并分析性能

**祝测试顺利！** 🚀
