# 快速開始指南

## 🚀 多機器測試快速指令

### 機器 A/B（17 個測試）

```bash
# 1. 啟動環境
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 2. 執行測試
docker exec -it vllm-bench-client bash /root/benchmark_tests/scripts/run_machine_AB_tests.sh

# 3. 打包結果（完成後）
tar -czf machine_AB_results.tar.gz bench_results/pcie/
```

**測試內容**：
- Group 1: 7B + TP=1 (配置 A+B, 6 測試)
- Group 2: 7B + TP=2 (配置 B, 3 測試)
- Group 3: 13B + TP=1 (配置 A, 2 測試)
- Group 4: 13B + TP=2 (配置 B, 3 測試)
- Group 5: 30B + TP=2 (配置 B, 3 測試)

---

### 機器 C（12 個測試）

```bash
# 1. 啟動環境
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 2. 執行測試
docker exec -it vllm-bench-client bash /root/benchmark_tests/scripts/run_machine_C_tests.sh

# 3. 合併結果（從機器 A/B 複製過來）
scp user@machine-ab:/path/to/machine_AB_results.tar.gz .
tar -xzf machine_AB_results.tar.gz
```

**測試內容**：
- Group 1: 7B + TP=1 (3 測試)
- Group 2: 7B + TP=2 (3 測試)
- Group 3: 13B + TP=2 (3 測試)
- Group 4: 30B + TP=2 (3 測試)

---

## 📋 測試組合速查表

### 機器 A/B 測試列表

| 組別 | vLLM Server 命令 | 測試 ID | 配置切換 |
|-----|-----------------|---------|---------|
| **Group 1** | `vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 1 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 1A-1k, 1A-2k, 1A-4k<br>1B-1k, 1B-2k, 1B-4k | A → B |
| **Group 2** | `vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 2B-1k, 2B-2k, 2B-4k | B |
| **Group 3** | `vllm serve meta-llama/Llama-2-13b-hf --tensor-parallel-size 1 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 3A-1k, 3A-2k | A |
| **Group 4** | `vllm serve meta-llama/Llama-2-13b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 3B-1k, 3B-2k, 3B-4k | B |
| **Group 5** | `vllm serve meta-llama/Llama-2-30b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 4B-1k, 4B-2k, 4B-4k | B |

### 機器 C 測試列表

| 組別 | vLLM Server 命令 | 測試 ID |
|-----|-----------------|---------|
| **Group 1** | `vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 1 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 1C-1k, 1C-2k, 1C-4k |
| **Group 2** | `vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 2C-1k, 2C-2k, 2C-4k |
| **Group 3** | `vllm serve meta-llama/Llama-2-13b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 3C-1k, 3C-2k, 3C-4k |
| **Group 4** | `vllm serve meta-llama/Llama-2-30b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager` | 4C-1k, 4C-2k, 4C-4k |

---

## 🔧 vLLM Server 操作

### 啟動 Server（在 vllm-server 容器內）

```bash
# 進入容器
docker exec -it vllm-server bash

# 啟動 server（根據上表選擇對應命令）
vllm serve <model> --tensor-parallel-size <1|2> --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

### 停止 Server

```bash
# 在 server 容器內按 Ctrl+C
# 或從外部強制停止
docker exec vllm-server pkill -f "vllm serve"
```

### 檢查 Server 狀態

```bash
# 健康檢查
curl http://localhost:8000/health

# 查看載入的模型
curl http://localhost:8000/v1/models
```

---

## 📊 查看結果

```bash
# 查看所有結果
ls -lh bench_results/pcie/

# 統計測試數量
ls bench_results/pcie/*.json | wc -l

# 快速查看單個結果
python3 -m json.tool bench_results/pcie/A_7B_TP1_1k_*.json

# 提取關鍵指標
cat bench_results/pcie/A_7B_TP1_1k_*.json | jq '{
  test_id: .test_metadata.test_id,
  config: .test_metadata.hardware_config,
  throughput: .throughput,
  ttft: .ttft,
  tpot: .tpot
}'
```

---

## ⚡ 並行執行策略

兩台機器可以**同時執行**以節省時間：

```
時間軸：
│
├─ 機器 A/B 開始測試 ──────────────────────┐
│                                          │
├─ 機器 C 開始測試 ────────────────┐        │
│                                │        │
│                                ├─ 1-1.5h│
│                                │        │
│                                結束 ────┘
│                                          │
│                                          ├─ 1.5-2h
│                                          │
│                                          結束
│
總時間：~2.5 小時（並行） vs ~3.5 小時（串行）
```

---

## 🆘 常見問題

### Server 啟動失敗

```bash
# 檢查 GPU
docker exec vllm-server rocm-smi

# 查看詳細錯誤
docker logs vllm-server

# VRAM 不足時降低使用率
vllm serve <model> --gpu-memory-utilization 0.7 --enforce-eager
```

### 測試腳本中斷

```bash
# 測試結果已保存，可以手動繼續
# 查看已完成的測試
ls bench_results/pcie/

# 手動執行剩餘測試
/root/benchmark_tests/scripts/run_pcie_benchmark.sh --config <X> --model <YB> --tp <Z> --input-len <N>
```

### 結果文件遺失

```bash
# 檢查容器內的結果
docker exec vllm-bench-client ls -lh /root/bench_results/pcie/

# 從容器複製出來
docker cp vllm-bench-client:/root/bench_results/pcie ./bench_results/
```

---

**完整文檔**: 請參考 [README.md](README.md) 和 [test_matrix.md](test_matrix.md)
