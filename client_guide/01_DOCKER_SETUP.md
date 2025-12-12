# Docker 環境設置指南

## 📋 前置需求

- Docker 已安裝（推薦 Docker 20.10+）
- Docker Compose v2 已安裝
- AMD GPU 驅動 (ROCm) 已正確設置
- 足夠的磁碟空間（建議 100GB+ 用於模型和結果）

## 🚀 啟動步驟

### 步驟 1: 進入 Docker 配置目錄

```bash
cd docker_setup
```

### 步驟 2: 啟動容器

```bash
docker compose -f docker-compose.bench.yml up -d
```

**預期輸出**:
```
[+] Running 3/3
 ✔ Network docker_setup_vllm-network      Created
 ✔ Container vllm-server                  Started
 ✔ Container vllm-bench-client            Started
```

### 步驟 3: 確認容器狀態

```bash
docker compose -f docker-compose.bench.yml ps
```

**預期輸出**:
```
NAME                IMAGE                                      STATUS
vllm-bench-client   rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006   Up
vllm-server         rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006   Up
```

---

## 🔍 驗證環境

### 檢查 GPU 可用性

```bash
# 在服務器容器中檢查 GPU
docker exec vllm-server rocm-smi
```

**預期輸出**: 顯示 GPU 列表和使用情況

### 檢查網路連接

```bash
# 測試容器間網路
docker exec vllm-bench-client ping -c 3 vllm-server
```

**預期輸出**: 成功 ping 通

---

## 📦 容器說明

### vllm-server
- **用途**: 運行 vLLM 推論服務器
- **端口**: 8000
- **GPU**: 可訪問所有 AMD GPU
- **掛載目錄**:
  - `~/.cache/huggingface` → 模型緩存
  - `../benchmark_tests/scripts` → 測試腳本
  - `../bench_results` → 測試結果

### vllm-bench-client
- **用途**: 運行基準測試客戶端
- **連接**: 通過網路連接到 vllm-server
- **掛載目錄**: 同 vllm-server

---

## 🛑 停止與清理

### 停止容器（保留數據）

```bash
docker compose -f docker-compose.bench.yml stop
```

### 完全移除容器

```bash
docker compose -f docker-compose.bench.yml down
```

### 清理所有數據（謹慎！）

```bash
# 刪除容器和網路
docker compose -f docker-compose.bench.yml down

# 清理測試結果
rm -rf ../bench_results/production/*
rm -rf ../bench_results/scaling/*
rm -rf ../output_plots/*
```

---

## ⚠️ 常見問題

### 問題: 端口 8000 被占用

**解決方案**: 修改 `docker-compose.bench.yml` 中的端口映射

```yaml
ports:
  - "8001:8000"  # 改用 8001 端口
```

### 問題: GPU 不可用

**檢查步驟**:
```bash
# 1. 檢查主機 GPU
rocm-smi

# 2. 檢查設備權限
ls -l /dev/kfd /dev/dri

# 3. 確認用戶在 video 群組
groups | grep video
```

### 問題: 容器無法啟動

**檢查日誌**:
```bash
docker compose -f docker-compose.bench.yml logs vllm-server
docker compose -f docker-compose.bench.yml logs vllm-bench-client
```

---

## ✅ 環境就緒檢查清單

- [ ] 容器成功啟動 (`docker ps` 顯示兩個容器)
- [ ] GPU 可訪問 (`docker exec vllm-server rocm-smi` 成功)
- [ ] 網路連通 (`ping` 測試成功)
- [ ] 掛載目錄正確 (`docker exec vllm-bench-client ls /root/benchmark_tests/scripts`)

**✓ 環境設置完成，可以進行下一步：vLLM 服務器啟動**
