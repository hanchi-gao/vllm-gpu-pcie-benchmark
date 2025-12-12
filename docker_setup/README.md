# Docker 環境設置

這個目錄包含 Docker 相關的配置和啟動腳本。

## 文件說明

- `docker-compose.bench.yml` - Docker Compose 配置文件

## 使用方法

### 啟動服務

```bash
cd /home/user/vllm_t/docker_setup
docker compose -f docker-compose.bench.yml up -d
```

### 停止服務

```bash
docker compose -f docker-compose.bench.yml down
```

### 查看日誌

```bash
# vLLM 服務器日誌
docker logs vllm-server -f

# Benchmark 客戶端日誌
docker logs vllm-bench-client -f
```

### 進入容器

```bash
# 進入 benchmark 客戶端容器
docker exec -it vllm-bench-client bash

# 進入 vLLM 服務器容器
docker exec -it vllm-server bash
```

## 服務說明

### vllm-server
- vLLM 推論服務器
- 端口: 8000
- GPU: 使用所有可用 AMD GPU (ROCm)
- 掛載目錄:
  - `~/.cache/huggingface` → `/root/.cache/huggingface` (模型緩存)
  - `../benchmark_tests/scripts` → `/root/benchmark_tests/scripts` (測試腳本)
  - `../bench_results` → `/root/bench_results` (測試結果)

### vllm-bench-client
- 基準測試客戶端環境
- 連接到 vllm-server 進行測試
- 掛載目錄:
  - `~/.cache/huggingface` → `/root/.cache/huggingface` (模型緩存)
  - `../benchmark_tests/scripts` → `/root/benchmark_tests/scripts` (測試腳本)
  - `../bench_results` → `/root/bench_results` (測試結果)

## 目錄結構對應

Docker Compose 文件掛載了以下項目目錄:

```
vllm_t/
├── benchmark_tests/scripts/  → /root/benchmark_tests/scripts (容器內)
├── bench_results/            → /root/bench_results (容器內)
└── docker_setup/             (本目錄)
    └── docker-compose.bench.yml
```

## 健康檢查

```bash
# 檢查 vLLM 服務器狀態
curl http://localhost:8000/health

# 檢查容器狀態
docker ps | grep vllm

# 檢查 GPU 可用性
docker exec vllm-bench-client rocm-smi
```

## 故障排除

### 容器無法啟動
```bash
# 查看詳細日誌
docker compose -f docker-compose.bench.yml logs

# 重新構建並啟動
docker compose -f docker-compose.bench.yml up -d --force-recreate
```

### GPU 不可用
```bash
# 檢查 GPU (在客戶端容器)
docker exec vllm-bench-client rocm-smi

# 檢查 ROCm
docker exec vllm-bench-client rocminfo

# 檢查設備權限
ls -l /dev/kfd /dev/dri
```

### 端口被占用
修改 `docker-compose.bench.yml` 中的端口映射:
```yaml
ports:
  - "8001:8000"  # 改為其他端口
```

### 容器名稱衝突
```bash
# 停止並移除舊容器
docker compose -f docker-compose.bench.yml down

# 或手動移除
docker rm -f vllm-server vllm-bench-client
```

## 注意事項

1. **使用 `docker compose` 而非 `docker-compose`** - 新版本已移除 `version` 欄位
2. **路徑使用相對路徑** - 所有掛載路徑使用 `../` 相對於 docker_setup 目錄
3. **容器名稱** - vllm-bench-client (非 vllm-bench)
4. **網絡** - 兩個容器通過 `vllm-network` 橋接網絡互相通信
