# 文档中心

vLLM ROCm 测试工具集的完整文档。

## 📚 文档列表

### 📘 guides/ - 使用指南

#### [AMD_OFFICIAL_VLLM_GUIDE.md](guides/AMD_OFFICIAL_VLLM_GUIDE.md) ⭐⭐⭐
**AMD 官方 vLLM 容器使用指南**

基于 AMD ROCm 官方文档的完整指南：
- 官方 Docker 镜像说明
- 关键配置参数详解
- gfx1201 优化建议
- 性能基准测试方法
- 高级用法和 API 服务器
- 故障排查完整指南

**推荐**: 首次使用必读

#### [CONTAINER_TESTING.md](guides/CONTAINER_TESTING.md) ⭐⭐
**容器内测试完整指南**

容器内测试的详细步骤：
- 3 种容器选择方法
- 环境检查清单
- 预制测试脚本使用
- 交互式 Python 测试
- GPU 监控和调试技巧
- 性能测试方法
- 常见问题解答

**推荐**: 需要在容器内调试时参考

## 🚀 快速导航

### 从哪里开始？

1. **完全新手** → 先看 [../QUICKSTART.md](../QUICKSTART.md)（3 步快速开始）
2. **需要详细配置** → [guides/AMD_OFFICIAL_VLLM_GUIDE.md](guides/AMD_OFFICIAL_VLLM_GUIDE.md)
3. **容器内测试** → [guides/CONTAINER_TESTING.md](guides/CONTAINER_TESTING.md)
4. **主项目 README** → [../README.md](../README.md)

## 📖 文档结构

```
docs/
├── guides/                 # 使用指南
│   ├── AMD_OFFICIAL_VLLM_GUIDE.md    # AMD 官方指南（详细）
│   └── CONTAINER_TESTING.md          # 容器测试指南
└── README.md              # 本文件
```

## 🎯 按需求查找

### 我想知道...

**如何快速开始？**
→ [../QUICKSTART.md](../QUICKSTART.md)

**如何配置 vLLM？**
→ [guides/AMD_OFFICIAL_VLLM_GUIDE.md](guides/AMD_OFFICIAL_VLLM_GUIDE.md) - "关键配置参数" 章节

**如何在容器内测试？**
→ [guides/CONTAINER_TESTING.md](guides/CONTAINER_TESTING.md) - "快速开始" 章节

**如何使用本地模型？**
→ [../README.md](../README.md) - "常见问题" 章节

**如何解决 dtype 错误？**
→ [../README.md](../README.md) - "常见问题" 或使用 `test_vllm_auto.py`

**如何优化性能？**
→ [guides/AMD_OFFICIAL_VLLM_GUIDE.md](guides/AMD_OFFICIAL_VLLM_GUIDE.md) - "针对 gfx1201 的优化" 章节

**遇到错误怎么办？**
→ [guides/AMD_OFFICIAL_VLLM_GUIDE.md](guides/AMD_OFFICIAL_VLLM_GUIDE.md) - "故障排查" 章节

## 🔗 外部资源

### AMD 官方文档

- [vLLM 推理性能测试](https://rocm.docs.amd.com/en/latest/how-to/rocm-for-ai/inference/benchmark-docker/vllm.html)
- [构建 vLLM 容器](https://rocm.blogs.amd.com/software-tools-optimization/vllm-container/README.html)
- [Radeon GPU 上使用 vLLM](https://rocm.docs.amd.com/projects/radeon/en/latest/docs/advanced/vllm/build-docker-image.html)

### vLLM 官方

- [vLLM GitHub](https://github.com/vllm-project/vllm)
- [vLLM 文档](https://docs.vllm.ai/)

## 📝 文档贡献

文档已精简，只保留核心使用指南。如需补充，建议：

1. **新手入门** → 补充到 QUICKSTART.md
2. **配置参数** → 补充到 AMD_OFFICIAL_VLLM_GUIDE.md
3. **测试方法** → 补充到 CONTAINER_TESTING.md

---

**总结**: 两份核心指南涵盖了所有使用场景，简洁实用！
