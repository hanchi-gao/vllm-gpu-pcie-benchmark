# test_vllm_serve.py 内存配置修复

## 🐛 问题说明

初始版本的 `test_vllm_serve.py` 使用了与 `test_vllm_auto.py` 相同的默认参数（`gpu_util=0.8`, `max_len=1024`），但 vLLM API 服务器模式需要**更多额外内存**来运行服务器进程和通信开销。

### 错误信息

```
ValueError: Free memory on device (5.31/31.86 GiB) on startup is less than
desired GPU memory utilization (0.8, 25.49 GiB).
Decrease GPU memory utilization or reduce GPU memory used by other processes.
```

**原因**:
- 你的 GPU 当前只有 **5.31 GB** 可用内存（可能有其他进程占用）
- API 服务器模式默认请求 80% (25.49 GB)
- 服务器进程本身需要额外的内存开销

---

## ✅ 修复方案

### 1. 降低默认参数

已将 `test_vllm_serve.py` 的默认值调整为：

| 参数 | 旧值 | 新值 | 原因 |
|------|------|------|------|
| `--max-len` | 1024 | **512** | 减少 KV cache 内存 |
| `--gpu-util` | 0.8 | **0.3** | 为服务器进程预留空间 |

### 2. 代码修改

**修改位置 1**: `VLLMServer.__init__` 默认参数
```python
# 修改前
def __init__(self, model_name: str, port: int = 8000,
             gpus: int = 1, max_len: int = 1024, gpu_util: float = 0.8):

# 修改后
def __init__(self, model_name: str, port: int = 8000,
             gpus: int = 1, max_len: int = 1024, gpu_util: float = 0.3):
```

**修改位置 2**: argparse 默认参数
```python
# 修改前
parser.add_argument("--max-len", type=int, default=1024, help="最大序列长度")
parser.add_argument("--gpu-util", type=float, default=0.8, help="GPU 内存使用率")

# 修改后
parser.add_argument("--max-len", type=int, default=512, help="最大序列长度")
parser.add_argument("--gpu-util", type=float, default=0.3, help="GPU 内存使用率 (0.0-1.0)")
```

---

## 🎯 使用建议

### 基础测试（推荐）

```bash
# 使用新的默认值（gpu_util=0.3, max_len=512）
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m
```

### 根据可用内存调整

**检查可用内存**:
```bash
# 在容器内运行
rocm-smi

# 或使用 Python
python3 -c "import torch; print(f'可用内存: {torch.cuda.mem_get_info()[0] / 1024**3:.2f} GB')"
```

**内存充足时（> 20 GB 可用）**:
```bash
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --gpu-util 0.6 \
  --max-len 1024
```

**内存紧张时（< 10 GB 可用）**:
```bash
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m \
  --gpu-util 0.2 \
  --max-len 256
```

**内存非常紧张时（< 5 GB 可用）**:
```bash
# 先清理 GPU 内存
python3 -c "import torch; torch.cuda.empty_cache()"

# 使用最小配置
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m \
  --gpu-util 0.15 \
  --max-len 128
```

---

## 📊 内存使用对比

### test_vllm_auto.py（直接 API 模式）

| 模型 | max_len | gpu_util | 预估内存 |
|------|---------|----------|---------|
| opt-125m | 1024 | 0.8 | ~2 GB |
| Qwen-7B | 1024 | 0.8 | ~15 GB |

### test_vllm_serve.py（服务器模式）

| 模型 | max_len | gpu_util | 预估内存 | 说明 |
|------|---------|----------|---------|------|
| opt-125m | 512 | 0.3 | ~1 GB | 默认配置 ✅ |
| opt-125m | 1024 | 0.5 | ~2.5 GB | 需要更多内存 |
| Qwen-7B | 512 | 0.3 | ~7 GB | 保守配置 |
| Qwen-7B | 1024 | 0.5 | ~16 GB | 需要充足内存 |

**服务器模式额外开销**:
- FastAPI 服务器进程: ~500 MB
- 多进程通信: ~200 MB
- 请求缓冲区: ~300 MB
- **总计额外开销**: ~1 GB

---

## 🔧 故障排查

### 问题 1: 仍然内存不足

**症状**: 即使使用默认参数仍然 OOM

**解决方案**:
```bash
# 1. 检查是否有其他进程占用 GPU
rocm-smi

# 2. 清理 GPU 内存
python3 -c "import torch; torch.cuda.empty_cache()"

# 3. 进一步降低参数
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m \
  --gpu-util 0.15 \
  --max-len 128
```

### 问题 2: 想要使用更高的 gpu_util

**症状**: 默认 0.3 太保守，想提高性能

**解决方案**:
```bash
# 先确认可用内存充足
python3 -c "import torch; free, total = torch.cuda.mem_get_info(); print(f'可用: {free/1024**3:.2f} GB / 总计: {total/1024**3:.2f} GB')"

# 如果可用内存 > 15 GB，可以提高到 0.5
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --gpu-util 0.5

# 如果可用内存 > 25 GB，可以提高到 0.7
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --gpu-util 0.7 \
  --max-len 2048
```

### 问题 3: 其他进程占用内存

**检查占用**:
```bash
rocm-smi
# 查看 "Memory Usage" 列
```

**清理方法**:
- 关闭其他使用 GPU 的程序
- 退出所有 Python 进程
- 如果是容器，重启容器

---

## 💡 最佳实践

### 1. 先测试小模型

```bash
# 使用默认配置测试 opt-125m
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m
```

### 2. 逐步增大模型和参数

```bash
# 确认小模型成功后，测试 3-4B 模型
python3 /root/container_scripts/test_vllm_serve.py google/gemma-3-4b-it

# 再测试 7B 模型
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct

# 如果需要更长序列，逐步增加
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --max-len 1024
```

### 3. 监控内存使用

在另一个终端运行：
```bash
watch -n 1 rocm-smi
```

---

## 🆚 两种模式的内存配置

| 脚本 | 默认 gpu_util | 默认 max_len | 适用场景 |
|------|--------------|-------------|---------|
| **test_vllm_auto.py** | 0.8 | 1024 | 直接推理，内存效率高 |
| **test_vllm_serve.py** | 0.3 | 512 | API 服务器，需预留开销 |

**建议**:
- 快速测试用 `test_vllm_auto.py`
- 生产部署验证用 `test_vllm_serve.py`（记得调整参数）

---

## 📚 相关文档

- [test_vllm_serve.py 使用指南](NEW_SERVE_SCRIPT.md)
- [容器测试指南](docs/guides/CONTAINER_TESTING.md)
- [GPU 参数说明](GPU_PARAM_UPDATE.md)

---

## 🎉 总结

修复后的 `test_vllm_serve.py`:
- ✅ 默认参数更保守（`gpu_util=0.3`, `max_len=512`）
- ✅ 适合内存受限的环境
- ✅ 可根据实际情况调整参数
- ✅ 为 API 服务器模式预留足够开销

现在可以在内存受限的环境下成功运行 API 服务器测试了！
