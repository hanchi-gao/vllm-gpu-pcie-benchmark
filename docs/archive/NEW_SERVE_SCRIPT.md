# 新增：vLLM API 服务器测试脚本

## 📝 概述

新增了 `test_vllm_serve.py` 脚本，用于测试 vLLM 的 OpenAI 兼容 API 服务器模式。

## ✨ 功能特性

### 自动化测试流程

1. **自动启动服务器**: 使用正确的参数启动 vLLM API 服务器
2. **等待服务器就绪**: 轮询健康检查端点，最多等待 3 分钟
3. **执行 4 项测试**:
   - 查询 `/v1/models` - 列出可用模型
   - 测试 `/v1/completions` - 文本补全
   - 测试 `/v1/chat/completions` - 聊天对话
   - 测试流式输出 - Streaming 模式
4. **自动清理**: 测试完成后自动关闭服务器

### 支持的参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `model` | `facebook/opt-125m` | 模型名称 |
| `--port` | `8000` | API 服务器端口 |
| `--gpus` | `1` | GPU 数量（tensor_parallel_size）|
| `--max-len` | `1024` | 最大序列长度 |
| `--gpu-util` | `0.8` | GPU 内存使用率 |

### 自动功能

- ✅ **自动 dtype 检测**: 根据模型名称选择 float16/bfloat16
- ✅ **自动端口管理**: 可自定义端口避免冲突
- ✅ **自动错误处理**: 服务器启动失败时显示详细错误
- ✅ **自动资源清理**: Ctrl+C 或测试完成后自动关闭服务器

## 🚀 使用方法

### 基础用法

```bash
# 进入容器
./host_scripts/enter_vllm_container.sh

# 测试小模型
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m

# 测试 7B 模型
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct
```

### 自定义配置

```bash
# 使用不同端口
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --port 8080

# 多 GPU
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --gpus 2

# 完整配置
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --port 8000 \
  --gpus 2 \
  --max-len 2048 \
  --gpu-util 0.85
```

### 查看帮助

```bash
python3 /root/container_scripts/test_vllm_serve.py --help
```

## 📊 测试输出示例

```
============================================================
启动 vLLM API 服务器
============================================================
模型: facebook/opt-125m
端口: 8000
dtype: float16
GPU 数量: 1
最大序列长度: 1024
GPU 内存使用率: 0.8

执行命令: python3 -m vllm.entrypoints.openai.api_server --model facebook/opt-125m ...

⏳ 启动服务器（这可能需要几分钟）...
  等待中... (10/180 秒)
  等待中... (20/180 秒)
✓ 服务器就绪！(45.2 秒)

============================================================
开始 API 测试
============================================================

[额外] 查询可用模型
  ✓ 成功
  可用模型:
    - facebook/opt-125m

[测试 1/3] Completions API
  ✓ 成功
  Prompt: Once upon a time
  输出: , there was a young girl named Lucy who lived in a small village...
  Tokens: 50 生成, 55 总计

[测试 2/3] Chat Completions API
  ✓ 成功
  User: What is the capital of France?
  Assistant: The capital of France is Paris.
  Tokens: 8 生成, 28 总计

[测试 3/3] 流式输出
  ✓ 成功
  Prompt: The meaning of life is
  输出:  to find happiness and fulfillment in everything we do.
  Tokens: 15 个 chunks

============================================================
测试完成: 4/4 通过
============================================================

正在关闭服务器...
✓ 服务器已关闭
```

## 🆚 对比：test_vllm_auto.py vs test_vllm_serve.py

| 特性 | test_vllm_auto.py | test_vllm_serve.py |
|------|-------------------|-------------------|
| **测试方式** | 直接调用 vLLM Python API | 通过 HTTP API 调用 |
| **启动时间** | 快（~30-60秒） | 较慢（~1-2分钟）|
| **适用场景** | 快速验证模型是否可用 | 验证 API 服务器功能 |
| **测试内容** | 基础推理功能 | API 端点、流式输出、聊天 |
| **服务器模式** | 无 | 启动完整的 HTTP 服务器 |
| **用途** | 开发测试 | 生产部署验证 |
| **OpenAI 兼容** | 否 | 是 |

## 📚 测试的 API 端点

### 1. GET /health
- **用途**: 健康检查
- **返回**: 服务器状态

### 2. GET /v1/models
- **用途**: 列出可用模型
- **返回**: 模型列表（JSON）

### 3. POST /v1/completions
- **用途**: 文本补全
- **参数**: prompt, max_tokens, temperature
- **返回**: 生成的文本

### 4. POST /v1/chat/completions
- **用途**: 聊天对话
- **参数**: messages, max_tokens, temperature
- **返回**: 助手回复

### 5. POST /v1/completions (stream=true)
- **用途**: 流式文本生成
- **返回**: Server-Sent Events (SSE)

## 🎯 使用场景

### 场景 1: 验证模型部署

```bash
# 确认模型可以作为 API 服务器运行
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct
```

### 场景 2: 测试不同端口

```bash
# 避免端口冲突
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --port 8001
```

### 场景 3: 性能测试

```bash
# 高内存配置
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct \
  --max-len 2048 \
  --gpu-util 0.9
```

### 场景 4: 多 GPU 测试

```bash
# 大模型多 GPU 部署
python3 /root/container_scripts/test_vllm_serve.py deepseek-ai/DeepSeek-R1-Distill-Llama-70B \
  --gpus 4 \
  --max-len 1024
```

## ⚠️ 注意事项

### 1. 端口占用

如果端口 8000 已被占用，使用 `--port` 指定其他端口：

```bash
python3 /root/container_scripts/test_vllm_serve.py facebook/opt-125m --port 8080
```

### 2. 启动时间

- 小模型（< 1B）: ~30-60 秒
- 中模型（3-7B）: ~1-2 分钟
- 大模型（> 13B）: ~2-5 分钟

### 3. 内存使用

服务器模式会占用更多内存。如果遇到 OOM，降低 `--gpu-util`:

```bash
python3 /root/container_scripts/test_vllm_serve.py Qwen/Qwen2-7B-Instruct --gpu-util 0.6
```

### 4. 中断测试

按 Ctrl+C 可以随时中断测试，脚本会自动清理并关闭服务器。

## 🔧 故障排查

### 问题 1: 服务器启动超时

**症状**: `✗ 服务器启动超时（180 秒）`

**解决方案**:
- 检查模型是否存在
- 降低 `--max-len` 或 `--gpu-util`
- 检查 GPU 内存是否足够

### 问题 2: 端口已被占用

**症状**: `Address already in use`

**解决方案**:
```bash
# 使用其他端口
python3 /root/container_scripts/test_vllm_serve.py MODEL --port 8001
```

### 问题 3: API 测试失败

**症状**: `✗ 失败: Connection refused`

**解决方案**:
- 确认服务器已启动（看到 "✓ 服务器就绪"）
- 检查防火墙设置
- 查看服务器日志输出

## 📖 相关文档

- **主文档**: [README.md](README.md)
- **容器测试指南**: [docs/guides/CONTAINER_TESTING.md](docs/guides/CONTAINER_TESTING.md)
- **AMD 官方指南**: [docs/guides/AMD_OFFICIAL_VLLM_GUIDE.md](docs/guides/AMD_OFFICIAL_VLLM_GUIDE.md)

## 🎉 总结

`test_vllm_serve.py` 提供了完整的 vLLM API 服务器测试流程：

✅ **自动化**: 从启动到关闭全自动
✅ **完整测试**: 覆盖所有主要 API 端点
✅ **易于使用**: 一条命令完成所有测试
✅ **OpenAI 兼容**: 测试 OpenAI 兼容 API
✅ **生产就绪**: 验证生产部署配置

现在你可以轻松验证 vLLM 作为 API 服务器的功能！
