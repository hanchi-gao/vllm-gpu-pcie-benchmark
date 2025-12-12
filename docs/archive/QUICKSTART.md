# 快速开始指南

**目标**: 在 AMD R9700 (gfx1201) 上测试 vLLM

## 🎯 推荐方法（3 步开始）

### 1. 进入官方 vLLM 容器

```bash
cd /home/user/vllm_t
./host_scripts/enter_vllm_container.sh
```

### 2. 在容器内运行测试

```bash
# 方法 A: 使用测试脚本（推荐）
python3 /root/container_scripts/test_vllm.py

# 方法 B: 手动测试
python3
```

### 3. 如果方法 A 成功

继续测试更大的模型：
```bash
python3 /root/container_scripts/test_vllm.py facebook/opt-1.3b
```

## 🔄 如果失败了怎么办？

### 备选方案 1: 使用 PyTorch 2.8

```bash
# 退出当前容器（Ctrl+D）
./host_scripts/enter_pytorch_container.sh

# 在新容器内测试
python3 /root/container_scripts/test_transformers.py
```

### 备选方案 2: 使用自动化脚本

```bash
# 在宿主机运行
./host_scripts/test_simple_pytorch.sh
```

## 📊 期望结果

### 成功的输出应该包含:

```
[1/5] 检查环境
  PyTorch: 2.x.x
  ROCm: True
  GPU 数量: 1

[2/5] 导入 vLLM
  vLLM 版本: 0.10.2

[3/5] 创建 LLM 实例
  ✓ 模型加载成功: X.X 秒

[4/5] 运行推理
  ✓ 推理成功
  输出 1: [生成的文本]

[5/5] 性能测试
  批量推理 (5个): X.XX 秒
  吞吐量: XXX tokens/秒

✓ 所有测试通过！
```

### 如果看到错误:

1. **"Engine core proc died"** → 查看 [docs/troubleshooting/ERROR_ANALYSIS.md](docs/troubleshooting/ERROR_ANALYSIS.md)
2. **"CUDA out of memory"** → 内存不足，使用更小的模型
3. **GPU 不可见** → 检查 Docker 设备参数

## 📚 详细文档

- **官方 vLLM 指南**: [docs/guides/AMD_OFFICIAL_VLLM_GUIDE.md](docs/guides/AMD_OFFICIAL_VLLM_GUIDE.md)
- **容器测试指南**: [docs/guides/CONTAINER_TESTING.md](docs/guides/CONTAINER_TESTING.md)
- **完整文档索引**: [docs/README.md](docs/README.md)

## 🎯 测试清单

进入容器后，按顺序检查：

```bash
# ✓ 1. GPU 可见
rocm-smi

# ✓ 2. ROCm 可用
python3 -c "import torch; print(torch.cuda.is_available())"

# ✓ 3. vLLM 可用
python3 -c "import vllm; print(vllm.__version__)"

# ✓ 4. 运行完整测试
python3 /root/container_scripts/test_vllm.py
```

## 🆘 快速帮助

| 问题 | 解决方案 |
|------|---------|
| 如何退出容器？ | `exit` 或 `Ctrl+D` |
| 如何重新进入？ | `./host_scripts/enter_vllm_container.sh` |
| 如何查看 GPU？ | 在容器内运行 `rocm-smi` |
| 测试脚本在哪？ | `/root/container_scripts/test_vllm.py` |
| 如何换其他镜像？ | 使用 `enter_pytorch_container.sh` |

---

**总结**: `./host_scripts/enter_vllm_container.sh` → `python3 /root/container_scripts/test_vllm.py`
