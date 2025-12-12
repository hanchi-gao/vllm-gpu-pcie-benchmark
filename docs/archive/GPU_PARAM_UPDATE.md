# test_vllm_auto.py GPU 参数更新

## 🎯 更新内容

为 `test_vllm_auto.py` 添加了命令行参数支持，可以灵活指定 GPU 数量和其他配置。

## ✨ 新增功能

### 命令行参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `模型名称` | `facebook/opt-125m` | 第一个位置参数，模型名称或路径 |
| `--gpus N` | `1` | 使用的 GPU 数量（tensor_parallel_size） |
| `--max-len N` | `256` | 最大序列长度 |
| `--gpu-util F` | `0.8` | GPU 内存使用率（0.0-1.0） |

## 📝 使用示例

### 基础用法

```bash
# 默认参数（1 GPU，256 max_len，0.8 gpu_util）
python3 /root/container_scripts/test_vllm_auto.py facebook/opt-125m
```

### 指定 GPU 数量

```bash
# 单 GPU
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --gpus 1

# 双 GPU（需要你的机器有 2 个 GPU）
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --gpus 2

# 4 个 GPU
python3 /root/container_scripts/test_vllm_auto.py meta-llama/Meta-Llama-3-8B-Instruct --gpus 4
```

### 自定义配置

```bash
# 更长的序列长度
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct --max-len 1024

# 降低内存使用（如果遇到 OOM）
python3 /root/container_scripts/test_vllm_auto.py google/gemma-3-4b-it --gpu-util 0.6 --max-len 128

# 组合参数
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct \
  --gpus 2 \
  --max-len 512 \
  --gpu-util 0.9
```

### 查看帮助

```bash
python3 /root/container_scripts/test_vllm_auto.py --help
```

输出：
```
usage: test_vllm_auto.py [-h] [--gpus GPUS] [--max-len MAX_LEN] [--gpu-util GPU_UTIL] [model]

vLLM 测试脚本 - 自动检测 dtype

positional arguments:
  model                模型名称

options:
  -h, --help           show this help message and exit
  --gpus GPUS          使用的 GPU 数量（tensor_parallel_size）
  --max-len MAX_LEN    最大序列长度
  --gpu-util GPU_UTIL  GPU 内存使用率 (0.0-1.0)
```

## 🔍 检查你的 GPU 数量

在容器内运行：

```bash
# 方法 1: 使用 rocm-smi
rocm-smi

# 方法 2: 使用 Python
python3 -c "import torch; print(f'可用 GPU 数量: {torch.cuda.device_count()}')"
```

## 💡 使用建议

### 单 GPU 系统（你的 R9700）

```bash
# 推荐配置
python3 /root/container_scripts/test_vllm_auto.py Qwen/Qwen2-7B-Instruct \
  --gpus 1 \
  --max-len 512 \
  --gpu-util 0.8
```

### 多 GPU 系统

```bash
# 大模型用多 GPU
python3 /root/container_scripts/test_vllm_auto.py deepseek-ai/DeepSeek-R1-Distill-Llama-70B \
  --gpus 4 \
  --max-len 1024 \
  --gpu-util 0.9
```

## ⚠️ 注意事项

1. **GPU 数量必须是 2 的幂次**: 1, 2, 4, 8（vLLM 限制）
2. **确保有足够的 GPU**: 如果指定 `--gpus 2` 但只有 1 个 GPU，会报错
3. **内存使用**:
   - 单 GPU: `gpu_util=0.8` 通常安全
   - 多 GPU: 可以提高到 `gpu_util=0.9`
4. **序列长度**:
   - 小模型（< 1B）: 可以用 512-2048
   - 中模型（3-7B）: 256-1024
   - 大模型（> 13B）: 128-512

## 📊 性能对比示例

### 单 GPU vs 双 GPU（理论）

| 配置 | 模型 | 吞吐量（预期） |
|------|------|---------------|
| 1 GPU | Qwen-7B | ~500 tokens/s |
| 2 GPU | Qwen-7B | ~900 tokens/s |
| 4 GPU | Llama-70B | ~300 tokens/s |

## 📚 相关文档

- [CONTAINER_TESTING.md](docs/guides/CONTAINER_TESTING.md) - 已更新参数说明
- [AMD_OFFICIAL_VLLM_GUIDE.md](docs/guides/AMD_OFFICIAL_VLLM_GUIDE.md) - tensor_parallel_size 详解

## 🎉 总结

现在你可以：
- ✅ 灵活指定 GPU 数量
- ✅ 自定义序列长度和内存使用
- ✅ 使用 `--help` 查看所有选项
- ✅ 适应不同的硬件配置

**最重要的是**: `test_vllm_auto.py` 仍然会自动检测和使用正确的 dtype！
