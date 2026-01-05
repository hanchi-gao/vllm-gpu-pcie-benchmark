# vLLM GPU PCIe 頻寬影響測試

在 AMD GPU (ROCm) 上測試不同 PCIe 頻寬配置對 vLLM 推論性能的影響。

> **專案來源**: 本專案從 [vllm_t](https://github.com/hanchi-gao/vllm_t) 複製而來，專注於 GPU PCIe 頻寬對 vLLM 性能的影響測試。

**硬體環境**: AMD Radeon AI PRO R9700 (gfx1201)
**Docker 映像**: `rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006`
**vLLM 版本**: 0.10.2

---

## 📋 測試配置 (最新)

### 核心測試參數

| 參數 | 值 | 說明 |
|------|-----|------|
| **輸入長度** | 1024 tokens | 固定輸入 |
| **輸出長度** | 128 tokens | 固定輸出 |
| **max-model-len** | 1280 tokens | vLLM 服務器設置 |
| **num_prompts** | 1-200 | 每個配置測試 200 次 |

### 硬體配置定義

| 配置代號 | 描述 | PCIe 配置 | GPU 數量 | 單卡頻寬 | 機器位置 |
|---------|------|-----------|---------|---------|---------|
| **A** | 消費型主板單卡 | 1×x16 | 1 | 32 GB/s | 機器 A/B |
| **B** | 雙卡 x8 配置 | 2×x8 | 2 | 16 GB/s | 機器 A/B |
| **C** | 四卡機雙卡 | 2×x16 | 2 | 32 GB/s | 機器 C |

**重要**: 配置 A 和 B 在同一台機器上（可切換 PCIe 設定），配置 C 在另一台獨立機器。

### 使用的模型

| 模型大小 | 完整模型名稱 | 說明 |
|---------|-------------|------|
| **7B** | `meta-llama/Llama-3.1-8B` | 輕量級模型，適合基準測試 |
| **14B** | `Qwen/Qwen3-14B` | 中型模型，測試 VRAM 壓力 |
| **30B** | `google/gemma-3-27b-it` | 大型模型，需 TP=2 |

### 測試矩陣

#### Machine C (4 個配置 × 200 prompts = 800 個結果)

| 測試 ID | 配置 | 模型 | TP | Input | Output | 描述 |
|---------|------|------|----|-------|--------|------|
| **1C-1k** | C | 7B | 1 | 1024 | 128 | 單卡 baseline |
| **2C-1k** | C | 7B | 2 | 1024 | 128 | x16 下 TP 通訊 |
| **3C-1k** | C | 14B | 2 | 1024 | 128 | Qwen 模型測試 |
| **4C-1k** | C | 30B | 2 | 1024 | 128 | 大模型測試 |

#### Machine A/B (6 個配置 × 200 prompts = 1,200 個結果)

| 測試 ID | 配置 | 模型 | TP | Input | Output | 描述 |
|---------|------|------|----|-------|--------|------|
| **1A-1k** | A | 7B | 1 | 1024 | 128 | 單卡 x16 baseline |
| **1B-1k** | B | 7B | 1 | 1024 | 128 | 單卡 x8 對照 |
| **2B-1k** | B | 7B | 2 | 1024 | 128 | x8 下 TP 通訊 |
| **3A-1k** | A | 14B | 1 | 1024 | 128 | 單卡 Qwen |
| **4B-1k** | B | 14B | 2 | 1024 | 128 | TP=2 Qwen |
| **5B-1k** | B | 30B | 2 | 1024 | 128 | TP=2 大模型 |

**總結果文件數**: 2,000 個 JSON 文件 (10 個配置 × 200 prompts)

---

## 🚀 快速開始

### 🏗️ 多機器測試架構

本專案支援兩種測試方式：
- **機器 A/B**: 配置 A 和 B 在同一台機器（6 個配置）
- **機器 C**: 配置 C 在獨立機器（4 個配置）

推薦使用**分機器批次測試腳本**以獲得最佳測試體驗。

---

### 選項 1: 機器 C 批次測試（推薦）

在配置 C 的機器上執行所有 4 個測試：

```bash
# 1. 啟動 Docker 環境
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 2. 執行機器 C 的所有測試（從容器外直接執行）
docker exec -it vllm-bench-client bash -c "cd /root && ./benchmark_tests/scripts/run_machine_C_tests.sh"

# 或者進入容器後執行
docker exec -it vllm-bench-client bash
cd /root
./benchmark_tests/scripts/run_machine_C_tests.sh
```

**腳本會自動提示你**：
- 何時需要啟動/重啟 vLLM server
- 每組測試的進度
- 需要使用的確切 vLLM 啟動命令

**測試分組**：
1. **Group 1**: 7B + TP=1 (1 個測試配置 × 200 prompts)
2. **Group 2**: 7B + TP=2 (1 個測試配置 × 200 prompts)
3. **Group 3**: 14B (Qwen) + TP=2 (1 個測試配置 × 200 prompts)
4. **Group 4**: 30B + TP=2 (1 個測試配置 × 200 prompts)

---

### 選項 2: 機器 A/B 批次測試

在配置 A/B 的機器上執行所有 6 個測試：

```bash
# 1. 啟動 Docker 環境
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 2. 執行機器 A/B 的所有測試（從容器外直接執行）
docker exec -it vllm-bench-client bash -c "cd /root && ./benchmark_tests/scripts/run_machine_AB_tests.sh"

# 或者進入容器後執行
docker exec -it vllm-bench-client bash
cd /root
./benchmark_tests/scripts/run_machine_AB_tests.sh
```

**測試分組**：
1. **Group 1**: 7B + TP=1 (Config A + B, 2 個配置)
2. **Group 2**: 7B + TP=2 (Config B, 1 個配置)
3. **Group 3**: 14B (Qwen) + TP=1 (Config A, 1 個配置)
4. **Group 4**: 14B (Qwen) + TP=2 (Config B, 1 個配置)
5. **Group 5**: 30B + TP=2 (Config B, 1 個配置)

---

### 選項 3: 單一測試（手動）

如果你想手動執行單一測試：

```bash
# 進入 client 容器
docker exec -it vllm-bench-client bash

# 在另一個終端啟動 vLLM server
docker exec -it vllm-server bash
vllm serve meta-llama/Llama-3.1-8B \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 1280 \
  --enforce-eager

# 回到 client，執行單一測試
cd /root
./benchmark_tests/scripts/run_pcie_benchmark.sh --config C --model 7B --tp 1 --input-len 1024
```

**參數說明**：
- `--config`: 硬體配置 (A, B, 或 C)
- `--model`: 模型大小 (7B, 14B, 或 30B)
- `--tp`: Tensor Parallel 大小 (1 或 2)
- `--input-len`: 輸入長度 (固定為 1024)

---

## 🎯 vLLM Server 啟動命令參考

### Group 1: 7B Model + TP=1

```bash
vllm serve meta-llama/Llama-3.1-8B \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 1280 \
  --enforce-eager
```

### Group 2: 7B Model + TP=2

```bash
vllm serve meta-llama/Llama-3.1-8B \
  --tensor-parallel-size 2 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 1280 \
  --enforce-eager
```

### Group 3: 14B (Qwen) Model + TP=2

```bash
vllm serve Qwen/Qwen3-14B \
  --tensor-parallel-size 2 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 1280 \
  --enforce-eager
```

### Group 4: 30B Model + TP=2

```bash
vllm serve google/gemma-3-27b-it \
  --tensor-parallel-size 2 \
  --gpu-memory-utilization 0.9 \
  --max-model-len 1280 \
  --enforce-eager
```

---

## 📊 結果文件

### 文件位置

所有測試結果保存在：
```
bench_results/pcie/
```

### 文件命名格式

```
{CONFIG}_{MODEL}_{TP}{INPUT}_np{NUM_PROMPTS}_{TIMESTAMP}.json
```

示例：
- `C_7B_TP1_1k_np1_20251231_120000.json`
- `C_14B_TP2_1k_np100_20251231_120100.json`
- `A_7B_TP1_1k_np200_20251231_120200.json`

### 結果格式

結果文件使用 vLLM 原生 JSON 格式（單行，無額外元數據）：

```json
{
  "date": "20251231-120000",
  "model_id": "meta-llama/Llama-3.1-8B",
  "num_prompts": 1,
  "request_rate": "inf",
  "duration": 4.30,
  "completed": 1,
  "total_input_tokens": 1024,
  "total_output_tokens": 128,
  "request_throughput": 0.232,
  "output_throughput": 29.74,
  "mean_ttft_ms": 57.65,
  "mean_tpot_ms": 33.43,
  "mean_itl_ms": 33.43,
  ...
}
```

---

## 🔧 自定義測試範圍

如果想要自定義 num_prompts 的測試範圍：

```bash
# 只測試 1-50 個 prompts
NUM_PROMPTS_START=1 NUM_PROMPTS_END=50 \
  ./benchmark_tests/scripts/run_pcie_benchmark.sh --config C --model 7B

# 快速測試 (只測試 1-3 個 prompts)
NUM_PROMPTS_END=3 \
  ./benchmark_tests/scripts/run_machine_C_tests.sh
```

---

## 📁 專案結構

```
vllm-gpu-pcie-benchmark/
├── benchmark_tests/
│   └── scripts/
│       ├── run_pcie_benchmark.sh       # 核心測試腳本
│       ├── run_machine_C_tests.sh      # Machine C 批次測試
│       └── run_machine_AB_tests.sh     # Machine A/B 批次測試
├── docker_setup/
│   └── docker-compose.bench.yml        # Docker 環境配置
├── bench_results/
│   └── pcie/                           # 測試結果目錄
└── README.md
```

---

## ⚙️ 重要配置說明

### max-model-len 設置

- **設定值**: 1280 tokens
- **計算**: 1024 (input) + 128 (output) + 128 (buffer) = 1280
- **注意**: 如果遇到 "maximum context length" 錯誤，請確保 vLLM server 使用 `--max-model-len 1280`

### num_prompts 說明

- 每個測試配置會執行 200 次（num_prompts 從 1 到 200）
- 這樣可以測試不同並發程度下的性能表現
- 結果文件數 = 測試配置數 × 200

### Tensor Parallel (TP) 說明

- **TP=1**: 單 GPU 運行，無跨 GPU 通訊
- **TP=2**: 雙 GPU 運行，測試 PCIe 頻寬對 GPU 間通訊的影響

---

## 🚨 常見問題

### 1. vLLM Server 連接失敗

```bash
# 檢查 server 是否運行
docker exec vllm-server ps aux | grep vllm

# 檢查端口
curl http://vllm-server:8000/health
```

### 2. max-model-len 錯誤

如果看到 "maximum context length is 896 tokens" 錯誤：

**原因**: vLLM server 啟動時沒有正確設置 `--max-model-len`

**解決**: 重啟 vLLM server，確保使用 `--max-model-len 1280`

### 3. VRAM 不足

對於大模型（14B, 30B），必須使用 `--tensor-parallel-size 2`：

```bash
# ✓ 正確
vllm serve Qwen/Qwen3-14B --tensor-parallel-size 2 ...

# ✗ 錯誤 (VRAM 不足)
vllm serve Qwen/Qwen3-14B --tensor-parallel-size 1 ...
```

### 4. 測試中斷

批次測試腳本支持中斷恢復：
- 已完成的測試結果會保存
- 可以從失敗的測試組重新開始

---

## 📈 下一步

測試完成後：

1. **收集結果**:
   ```bash
   # Machine C
   tar -czf machine_C_results.tar.gz bench_results/pcie/C_*.json

   # Machine A/B
   tar -czf machine_AB_results.tar.gz bench_results/pcie/[AB]_*.json
   ```

2. **合併結果**: 將兩台機器的結果合併到同一目錄

3. **分析數據**: 使用 Python/Jupyter Notebook 分析 JSON 結果

---

## 📝 更新日誌

### 2025-12-31
- 🔄 將測試從 request_rate 改為 num_prompts (1-200)
- 📉 簡化測試：只測試 1024 輸入長度
- 🔧 更新 max-model-len 從 4096 → 1280
- 🤖 將 14B 模型從 Llama-2-13b-hf 改為 Qwen/Qwen3-14B
- 🤖 將 30B 模型從 Llama-2-30b-hf 改為 google/gemma-3-27b-it
- 📊 結果文件使用 vLLM 原生 JSON 格式
- 🐛 修復腳本兼容性問題（`set -e` 與 `((VAR++))`）
- 📝 減少測試總數：從 24 個配置 → 10 個配置

---

## 🤝 貢獻

歡迎提交 Issue 或 Pull Request！

## 📄 授權

本專案遵循原專案 [vllm_t](https://github.com/hanchi-gao/vllm_t) 的授權條款。
