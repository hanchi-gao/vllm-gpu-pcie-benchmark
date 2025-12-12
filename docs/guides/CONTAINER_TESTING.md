# 容器测试快速指南

容器内测试的实际操作步骤。

> **配置参数详解**: 参见 [AMD_OFFICIAL_VLLM_GUIDE.md](AMD_OFFICIAL_VLLM_GUIDE.md)

## 🚀 1. 进入容器

```bash
cd /home/user/vllm_t

# 官方 vLLM 容器（推荐）
./host_scripts/enter_vllm_container.sh
```

**容器说明**:
- 镜像: `rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006`
- vLLM 版本: 0.11.0rc2.dev160 (实际运行版本)
- PyTorch: 2.9.0a0
- ROCm: 7.0.0 (HIP 7.0.51831)
- 状态: ✅ 已验证可用

**其他容器**:
- `enter_pytorch_container.sh` - PyTorch 2.8 + ROCm 7.1（备选）
- `enter_container.sh` - vLLM 0.11 开发版

## ✅ 2. 检查环境

```bash
# 查看 GPU
rocm-smi

# 检查 PyTorch
python3 -c "import torch; print(f'PyTorch: {torch.__version__}, GPU: {torch.cuda.is_available()}')"

# 检查 vLLM
python3 -c "import vllm; print(f'vLLM: {vllm.__version__}')"
```

## 🎯 3. 运行测试

### 方法 A: 自动测试（推荐）⭐

**自动处理 dtype，适合所有模型**:

```bash
# 测试小模型（默认使用 1 个 GPU）
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m

# 测试你的本地模型
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct
python3 /root/container_scripts/test_vllm_auto.py google/gemma-3-4b-it
python3 /root/container_scripts/test_vllm_auto.py meta-llama/Meta-Llama-3-8B-Instruct

# 指定使用多个 GPU（如果你有多个 GPU）
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --gpus 2

# 自定义更多参数
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --gpus 2 --max-len 512 --gpu-util 0.9
```

**test_vllm_auto.py 特性**:
- ✅ 自动检测模型需要的 dtype (float16/bfloat16)
- ✅ 自动处理 Gemma 3 等特殊模型
- ✅ 显示性能数据（吞吐量、加载时间）
- ✅ 5 步完整测试流程
- ✅ 支持多 GPU 并行推理（`--gpus N`）
- ✅ 可自定义序列长度和内存使用率

**命令行参数**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `模型名称` | `facebook/opt-125m` | 第一个位置参数 |
| `--gpus N` | `1` | 使用的 GPU 数量（tensor_parallel_size） |
| `--max-len N` | `256` | 最大序列长度 |
| `--gpu-util F` | `0.8` | GPU 内存使用率（0.0-1.0） |

**示例**:
```bash
# 查看帮助
python3 /root/container_scripts/test_vllm_auto.py --help

# 单 GPU，默认参数
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct

# 双 GPU，更长序列
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --gpus 2 --max-len 1024

# 单 GPU，低内存使用
python3 /root/container_scripts/test_vllm_auto.py google/gemma-3-4b-it --gpu-util 0.6 --max-len 128
```

---

### 方法 A2: API 服务器测试 🆕

**test_vllm_serve.py - 测试 OpenAI 兼容 API**:

```bash
# 基础测试（启动服务器 + 测试 API）
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m

# 测试本地模型
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct

# 使用不同端口
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --port 8080

# 自定义参数
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --gpus 2 \
  --max-len 1024 \
  --gpu-util 0.85
```

**test_vllm_serve.py 特性**:
- ✅ 自动启动 vLLM OpenAI API 服务器
- ✅ 测试 `/v1/completions` 端点
- ✅ 测试 `/v1/chat/completions` 端点
- ✅ 测试流式输出（streaming）
- ✅ 查询 `/v1/models` 端点
- ✅ 测试完成后自动关闭服务器

**命令行参数**:
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `模型名称` | `facebook/opt-125m` | 第一个位置参数 |
| `--port N` | `8000` | API 服务器端口 |
| `--gpus N` | `1` | 使用的 GPU 数量 |
| `--max-len N` | `512` | 最大序列长度 |
| `--gpu-util F` | `0.3` | GPU 内存使用率（API 服务器模式默认较低）|

**与 test_vllm_auto.py 的区别**:
| 特性 | test_vllm_auto.py | test_vllm_serve.py |
|------|-------------------|-------------------|
| 测试方式 | 直接 Python API | OpenAI 兼容 HTTP API |
| 适用场景 | 快速功能测试 | API 服务器测试 |
| 启动时间 | 快（~30秒） | 较慢（~2分钟）|
| 测试内容 | 推理功能 | API 端点、流式输出 |
| 用途 | 验证模型可用性 | 验证生产环境部署 |

---

### 方法 B: 基础测试

```bash
# 使用默认 float16
python3 /root/container_scripts/test_vllm.py facebook/opt-125m

# 指定模型
python3 /root/container_scripts/test_vllm.py Qwen/Qwen2-7B-Instruct
```

**注意**: 如果遇到 "float16 not supported" 错误，使用方法 A 的 `test_vllm_auto.py`。

### 方法 C: Transformers 备选

```bash
# 如果 vLLM 有问题，使用 Transformers
python3 /root/container_scripts/test_transformers.py
python3 /root/container_scripts/test_transformers.py gpt2
```

## 📊 4. 查看本地模型

```bash
# 列出所有已下载的模型
ls /app/models/hub/

# 你有这些模型可用:
# - facebook/opt-125m
# - google/gemma-3-4b-it
# - Qwen/Qwen2-7B-Instruct
# - meta-llama/Meta-Llama-3-8B-Instruct
# - mistralai/Mistral-7B-Instruct-v0.3
# - google/gemma-2-9b-it
# - deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
# - deepseek-ai/DeepSeek-R1-Distill-Llama-70B
```

## 🔧 5. 交互式测试

### 基础 Python 测试

```bash
python3
```

```python
from vllm import LLM, SamplingParams

# 加载模型
llm = LLM(
    "facebook/opt-125m",
    dtype="float16",
    enforce_eager=True,  # 必须！
    gpu_memory_utilization=0.8,
)

# 运行推理
outputs = llm.generate(
    ["Hello, my name is"],
    SamplingParams(temperature=0.8, max_tokens=20)
)

print(outputs[0].outputs[0].text)
```

### 测试中文模型

```python
from vllm import LLM, SamplingParams

# 使用 bfloat16 (Qwen 推荐)
llm = LLM(
    "Qwen/Qwen2-7B-Instruct",
    dtype="bfloat16",
    enforce_eager=True,
    max_model_len=512,
)

outputs = llm.generate(
    ["你好，请介绍一下自己:"],
    SamplingParams(temperature=0.7, max_tokens=100)
)

print(outputs[0].outputs[0].text)
```

### 测试 Gemma 3 (需要 bfloat16)

```python
from vllm import LLM, SamplingParams

# Gemma 3 必须使用 bfloat16
llm = LLM(
    "google/gemma-3-4b-it",
    dtype="bfloat16",  # 必须！
    enforce_eager=True,
)

outputs = llm.generate(
    ["Explain quantum computing:"],
    SamplingParams(max_tokens=100)
)

print(outputs[0].outputs[0].text)
```

## 📈 6. 批量测试

### 测试多个模型

```bash
# 在容器内
for model in facebook/opt-125m Qwen/Qwen2-7B-Instruct meta-llama/Meta-Llama-3-8B-Instruct; do
    echo "========================================="
    echo "测试: $model"
    echo "========================================="
    python3 /root/container_scripts/test_vllm_auto.py "$model"
    echo ""
done
```

### 性能基准测试

```python
from vllm import LLM, SamplingParams
import time

llm = LLM("facebook/opt-125m", enforce_eager=True)

# 预热
llm.generate(["warmup"], SamplingParams(max_tokens=10))

# 批量测试
for batch_size in [1, 5, 10, 20]:
    prompts = ["Test"] * batch_size
    start = time.time()
    outputs = llm.generate(prompts, SamplingParams(max_tokens=20))
    elapsed = time.time() - start
    tokens = sum(len(o.outputs[0].token_ids) for o in outputs)
    print(f"批量 {batch_size}: {tokens/elapsed:.1f} tokens/秒")
```

## 🐛 7. 常见问题快速解决

### Q: 出现 "float16 not supported" 错误？

```bash
# 使用 test_vllm_auto.py，会自动使用 bfloat16
python3 /root/container_scripts/test_vllm_auto.py google/gemma-3-4b-it
```

### Q: 内存不足？

```python
# 降低内存使用
llm = LLM(
    model="...",
    gpu_memory_utilization=0.6,  # 降到 60%
    max_model_len=256,            # 减小上下文
    enforce_eager=True,
)
```

### Q: 模型加载很慢？

第一次运行需要编译 GPU kernels（~18秒），之后会快很多（~2秒）。这是正常的。

### Q: 如何查看详细日志？

```bash
export VLLM_LOGGING_LEVEL=DEBUG
python3 /root/container_scripts/test_vllm_auto.py <model>
```

### Q: 如何监控 GPU？

```bash
# 实时监控（另开一个终端）
watch -n 1 rocm-smi
```

## 📋 8. 测试检查清单

```bash
# 1. GPU 可见
rocm-smi && echo "✓ GPU 可见"

# 2. PyTorch 可用
python3 -c "import torch; assert torch.cuda.is_available()" && echo "✓ PyTorch GPU"

# 3. vLLM 可用
python3 -c "import vllm" && echo "✓ vLLM 可用"

# 4. 运行测试
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m && echo "✓ 测试通过"
```

## 🎯 9. 推荐测试流程

### 新手流程

```bash
# 1. 进入容器
./host_scripts/enter_vllm_container.sh

# 2. 检查环境
rocm-smi
python3 -c "import vllm; print(vllm.__version__)"

# 3. 测试小模型
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m

# 4. 测试你的模型
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct
```

### 高级流程

```bash
# 1. 进入容器
./host_scripts/enter_vllm_container.sh

# 2. 启动 Python 交互式
python3
```

```python
# 3. 自定义配置
from vllm import LLM, SamplingParams

llm = LLM(
    "Qwen/Qwen2-7B-Instruct",
    dtype="bfloat16",
    max_model_len=1024,           # 更长的上下文
    gpu_memory_utilization=0.9,   # 更高的内存使用
    enforce_eager=True,
)

# 4. 测试
outputs = llm.generate(
    ["你的提示词"],
    SamplingParams(
        temperature=0.7,
        top_p=0.9,
        max_tokens=200
    )
)
```

## 📚 相关文档

- **配置参数详解**: [AMD_OFFICIAL_VLLM_GUIDE.md](AMD_OFFICIAL_VLLM_GUIDE.md)
- **主项目 README**: [../../README.md](../../README.md)
- **快速开始**: [../../QUICKSTART.md](../../QUICKSTART.md)

---

**总结**: 使用 `test_vllm_auto.py` 是最简单的方式，会自动处理所有 dtype 问题！
