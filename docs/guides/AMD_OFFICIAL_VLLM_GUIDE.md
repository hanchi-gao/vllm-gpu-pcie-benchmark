# AMD 官方 vLLM 容器使用指南

基于 AMD ROCm 官方文档的 vLLM 容器使用方法。

参考: [AMD ROCm vLLM 文档](https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html)

## 🎯 官方 Docker 镜像

### 推荐镜像

```bash
rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006
```

**包含内容**:
- vLLM 0.11.0rc2.dev160 (实际版本，而非标签的 0.10.2)
- PyTorch 2.9.0a0 (针对 AMD GPU 优化)
- ROCm 7.0.0 (HIP 7.0.51831)
- 预配置的推理环境

**支持的 GPU**:
- AMD Instinct MI355X, MI350X, MI325X, MI300X（数据中心 GPU）
- AMD Radeon AI PRO R9700（gfx1201，本项目使用的 GPU）

## 🚀 快速开始

### 1. 拉取镜像

```bash
docker pull rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006
```

### 2. 运行容器

```bash
# 使用我们的脚本
cd /home/user/vllm_t
./host_scripts/enter_vllm_container.sh

# 或者手动运行
docker run -it --rm \
  --network=host \
  --group-add=video \
  --ipc=host \
  --cap-add=SYS_PTRACE \
  --security-opt seccomp=unconfined \
  --device /dev/kfd \
  --device /dev/dri \
  --shm-size=16g \
  -v /home/user/.cache/huggingface:/app/models \
  -v /home/user/vllm_t/container_scripts:/root/container_scripts \
  -e HF_HOME="/app/models" \
  -e PYTORCH_ALLOC_CONF="max_split_size_mb:512" \
  rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006 \
  bash
```

### 3. 在容器内测试

```bash
# 方法 A: 自动测试（推荐）⭐
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m

# 方法 B: 基础测试
python3 /root/container_scripts/test_vllm.py

# 方法 C: 交互式 Python 测试
python3
```

**推荐使用 test_vllm_auto.py**，它会自动检测模型需要的 dtype (float16/bfloat16)。

详细测试步骤请参考: [CONTAINER_TESTING.md](CONTAINER_TESTING.md)

## 📋 关键配置参数

### Docker 运行参数

| 参数 | 说明 | 为什么需要 |
|------|------|-----------|
| `--network=host` | 使用主机网络 | 简化网络配置 |
| `--device /dev/kfd` | KFD 设备 | ROCm GPU 访问 |
| `--device /dev/dri` | DRI 设备 | GPU 渲染接口 |
| `--shm-size=16g` | 共享内存 | 大模型需要大内存 |
| `--group-add=video` | 视频组权限 | GPU 访问权限 |
| `--ipc=host` | IPC 命名空间 | 进程间通信 |

### 环境变量

| 变量 | 值 | 说明 |
|------|-----|------|
| `HF_HOME` | `/app/models` | Hugging Face 缓存目录 |
| `PYTORCH_ALLOC_CONF` | `max_split_size_mb:512` | 内存分配优化 |
| `VLLM_LOGGING_LEVEL` | `INFO` 或 `DEBUG` | 日志级别 |

### vLLM 模型参数

| 参数 | 推荐值 | 说明 |
|------|--------|------|
| `tensor_parallel_size` | `1` | 单 GPU 使用 1 |
| `dtype` | `float16` 或 `bfloat16` | 见下方 dtype 选择指南 |
| `max_model_len` | `256` - `2048` | 根据 GPU 内存调整 |
| `gpu_memory_utilization` | `0.7` - `0.9` | GPU 内存使用率 |
| `enforce_eager` | `True` | **必须！** 禁用 CUDA graphs |

#### dtype 选择指南

| 模型系列 | 推荐 dtype | 原因 |
|---------|-----------|------|
| OPT, GPT-2, Mistral | `float16` | 标准支持 |
| Llama 3 | `float16` 或 `bfloat16` | 都支持 |
| **Gemma 2/3** | **`bfloat16`** | 必须，float16 会报错 |
| Qwen 2 | `bfloat16` | 推荐 |
| DeepSeek R1 | `bfloat16` | 推荐 |

**提示**: 使用 `test_vllm_auto.py` 会自动选择正确的 dtype！

## 🎯 针对 gfx1201 的优化

### 已知信息

- **GPU**: AMD Radeon AI PRO R9700（gfx1201，RDNA 3 Pro）
- **ROCm 版本**: 7.0.0（容器内）
- **vLLM 版本**: 0.10.2（比 0.11.0rc2 更稳定）

### 推荐配置

```python
llm = LLM(
    model="facebook/opt-125m",  # 或其他小模型
    tensor_parallel_size=1,      # 单 GPU
    dtype="float16",             # 半精度
    max_model_len=256,           # 开始时使用小值
    gpu_memory_utilization=0.8,  # 80% GPU 内存
    enforce_eager=True,          # 禁用 CUDA graphs（gfx1201 支持可能不完整）
    disable_log_stats=True,      # 减少日志输出
)
```

### 如果遇到问题

1. **降低内存使用**:
   ```python
   gpu_memory_utilization=0.7  # 从 0.8 降到 0.7
   max_model_len=128           # 减小上下文长度
   ```

2. **启用详细日志**:
   ```bash
   export VLLM_LOGGING_LEVEL=DEBUG
   ```

3. **检查 GPU 可见性**:
   ```bash
   rocm-smi
   rocminfo | grep gfx
   ```

## 📊 性能基准

### AMD 官方基准测试

AMD 提供了针对以下模型的基准测试:
- Llama 2 70B
- Llama 3.1 405B FP4
- Llama 3.3 70B FP8

### 本项目测试目标

对于 gfx1201（16GB 显存）：

| 模型大小 | 预期性能 | 状态 |
|----------|----------|------|
| 小模型（125M-1B） | 2000-3000 tokens/s | 待测试 |
| 中模型（3B-7B） | 500-1500 tokens/s | 待测试 |
| 大模型（13B+） | 可能内存不足 | 待测试 |

## 🔧 高级用法

### 1. 运行 OpenAI 兼容的 API 服务器

```bash
python3 -m vllm.entrypoints.openai.api_server \
  --model facebook/opt-125m \
  --host 0.0.0.0 \
  --port 8000 \
  --dtype float16 \
  --max-model-len 256 \
  --gpu-memory-utilization 0.8
```

### 2. 批量推理

```python
from vllm import LLM, SamplingParams

llm = LLM("facebook/opt-125m", enforce_eager=True)

prompts = [
    "The future of AI is",
    "Machine learning will",
    "Deep learning has",
]

outputs = llm.generate(prompts, SamplingParams(max_tokens=50))

for output in outputs:
    print(f"Prompt: {output.prompt}")
    print(f"Output: {output.outputs[0].text}\n")
```

### 3. 测试不同模型

```bash
# 在容器内（自动处理 dtype）
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct
python3 /root/container_scripts/test_vllm_auto.py google/gemma-3-4b-it
```

更多测试示例请参考: [CONTAINER_TESTING.md](CONTAINER_TESTING.md)

## 🐛 故障排查

### 问题 1: "Engine core proc died unexpectedly"

**可能原因**:
- GPU 内存不足
- 模型与 GPU 架构不兼容
- vLLM 版本问题

**解决方案**:
1. 降低 `gpu_memory_utilization` 到 0.7
2. 减小 `max_model_len`
3. 使用更小的模型测试
4. 启用 `enforce_eager=True`

### 问题 2: GPU 不可见

**检查**:
```bash
# 在容器内
rocm-smi
# 应该能看到 GPU 信息

rocminfo | grep gfx
# 应该显示 gfx1100 或 gfx1201
```

**解决方案**:
- 确保 Docker 命令包含 `--device /dev/kfd --device /dev/dri`
- 检查 `--group-add=video` 是否存在

### 问题 3: 内存不足

**症状**:
```
RuntimeError: CUDA out of memory
```

**解决方案**:
```python
# 选项 1: 降低内存使用
llm = LLM(
    model="facebook/opt-125m",
    gpu_memory_utilization=0.6,  # 降低到 60%
    max_model_len=128,            # 减小长度
)

# 选项 2: 使用更小的模型
llm = LLM(model="facebook/opt-125m")  # 而不是 opt-1.3b
```

## 📚 AMD 官方资源

### 文档链接

1. **vLLM 推理性能测试**:
   https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html

2. **构建 vLLM 容器**:
   https://rocm.blogs.amd.com/software-tools-optimization/vllm-container/README.html

3. **MI300X 性能验证**:
   https://rocm.docs.amd.com/en/docs-6.3.3/how-to/rocm-for-ai/inference/vllm-benchmark.html

4. **Radeon GPU 上使用 vLLM**:
   https://rocm.docs.amd.com/projects/radeon/en/latest/docs/advanced/vllm/build-docker-image.html

### 官方 GitHub

- **vLLM 项目**: https://github.com/vllm-project/vllm
- **ROCm 文档**: https://github.com/RadeonOpenCompute/ROCm

## 🔄 版本对比

### vLLM 0.10.2 vs 0.11.0rc2

| 特性 | 0.10.2（当前） | 0.11.0rc2（测试失败） |
|------|----------------|----------------------|
| 稳定性 | ✅ 稳定发布版 | ⚠️ 候选版本 |
| gfx1201 支持 | ⏳ 待测试 | ❌ V1 引擎崩溃 |
| ROCm 版本 | 7.0.0 | 7.0.0 |
| 推荐使用 | ✅ 推荐 | ❌ 不推荐 |

## 🎯 下一步

1. **测试官方容器**:
   ```bash
   ./host_scripts/enter_vllm_container.sh
   python3 /root/container_scripts/test_vllm.py
   ```

2. **如果成功**: 记录性能数据，尝试更大的模型

3. **如果失败**: 切换到 PyTorch 2.8 容器或使用 Transformers

4. **性能调优**: 参考 AMD 官方基准测试方法

## 📝 相关文档

- [CONTAINER_TESTING.md](CONTAINER_TESTING.md) - 容器测试指南
- [../troubleshooting/ERROR_ANALYSIS.md](../troubleshooting/ERROR_ANALYSIS.md) - 错误分析
- [PYTORCH_2.8_GUIDE.md](PYTORCH_2.8_GUIDE.md) - PyTorch 2.8 备选方案

---

**总结**: 官方 vLLM 0.10.2 容器是最稳定的选择，优先测试这个版本。
