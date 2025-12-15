# vLLM 性能測試系統

在 AMD GPU (ROCm) 上使用 Docker Compose 部署 vLLM 服務器和客戶端進行全面性能測試與分析。

**硬體環境**: AMD Radeon AI PRO R9700 (gfx1201)
**Docker 映像**: `rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006`
**vLLM 版本**: 0.10.2

---

## ✅ 已測試模型列表

以下模型已在本環境中測試，確認可正常運行：

| 模型名稱 | 完整路徑 | 測試狀態 | 備註 |
|---------|---------|---------|------|
| **GPT-OSS 120B** | `openai/gpt-oss-120b` | ✅ 成功 | 需 4 GPU (tensor-parallel-size=4) |
| **Gemma 3 4B Instruct** | `google/gemma-3-4b-it` | ✅ 成功 | 輕量級模型，適合快速測試 |
| **Llama 3.1 8B** | `meta-llama/Llama-3.1-8B` | ✅ 成功 | Meta 官方模型 |
| **Qwen 3 8B** | `Qwen/Qwen3-8B` | ✅ 成功 | 阿里通義千問模型 |
| **Ministral 3 14B Instruct** | `mistralai/Ministral-3-14b-Instruct-2512` | ❌ 失敗 | 需要 vLLM ≥ 0.12.0，ROCm 官方映像尚未提供 |

### 使用方式

使用腳本的 `--model` 參數指定不同模型：

```bash
# 使用預設模型 (GPT-OSS 120B)
./run_scaling_bench_200.sh

# 使用 Gemma 3 4B
./run_scaling_bench_200.sh --model google/gemma-3-4b-it

# 使用 Llama 3.1 8B
./run_scaling_bench_200.sh --model meta-llama/Llama-3.1-8B

# 使用 Qwen 3 8B
./run_scaling_bench_200.sh --model Qwen/Qwen3-8B
```

### 結果檔案組織

不同模型的測試結果會自動儲存到對應的子資料夾：

```
bench_results/scaling/
├── gpt-oss-120b/
│   ├── gpt-oss-120b_scale_n1_20251210_120000.json
│   ├── gpt-oss-120b_scale_n2_20251210_120100.json
│   └── ...
├── gemma-3-4b-it/
│   ├── gemma-3-4b-it_scale_n1_20251210_130000.json
│   └── ...
├── Llama-3.1-8B/
│   ├── Llama-3.1-8B_scale_n1_20251210_140000.json
│   └── ...
└── Qwen3-8B/
    ├── Qwen3-8B_scale_n1_20251210_150000.json
    └── ...
```

---

## 📁 專案結構

```
vllm_t/
│
├── 📂 benchmark_tests/          # vLLM 推論基準測試
│   ├── scripts/                 # 測試腳本（容器內執行）
│   │   ├── run_benchmark.sh              # 通用基準測試（可自訂參數）
│   │   ├── run_production_bench.sh       # Production 測試（6種長度 × 5種並發）
│   │   ├── run_scaling_bench.sh          # 擴展性測試（1-1000 請求）
│   │   └── run_scaling_bench_200.sh      # 擴展性測試（1-200 詳細）
│   │
│   └── plot_scripts/            # 繪圖工具（主機端執行）
│       ├── plot_comprehensive_benchmark.py    # 綜合報告繪圖
│       ├── plot_normalized_benchmark.py       # 標準化報告繪圖
│       ├── plot_scaling_benchmark.py          # 擴展性報告繪圖（1-1000）
│       ├── plot_scaling_benchmark_200.py      # 擴展性報告繪圖（1-200）
│       ├── run_comprehensive_plot.sh          # 綜合報告生成器
│       ├── run_normalized_plot.sh             # 標準化報告生成器
│       ├── run_scaling_plot.sh                # 擴展性報告生成器（1-1000）
│       └── run_scaling_plot_200.sh            # 擴展性報告生成器（1-200）
│
├── 📂 docker_setup/             # Docker 環境配置
│   ├── docker-compose.bench.yml     # Docker Compose 配置文件
│   └── README.md                    # Docker 設置文檔
│
├── 📂 bench_results/            # 測試結果（自動生成，Git 忽略）
│   ├── production/              # Production 測試結果 (JSON)
│   └── scaling/                 # 擴展性測試結果 (JSON)
│
├── 📂 output_plots/             # 生成圖表（自動生成）
│   ├── benchmark_comprehensive.png    # 綜合報告（吞吐量、TTFT、TPOT）
│   ├── benchmark_normalized.png       # 標準化報告
│   ├── scaling_benchmark.png          # 擴展性報告（1-1000）
│   └── scaling_benchmark_200.png      # 擴展性報告（1-200）
│
├── 📂 docs/                     # 項目文檔與歷史資料
│   ├── troubleshooting/         # 故障排除指南
│   └── archive/                 # 歷史文檔
│
├── 📄 README.md                 # 本文檔
└── 📄 .gitignore                # Git 忽略規則
```

---

## 🎯 核心功能

### 1. Production 測試
測試不同 context length 和並發數組合的性能表現

**測試配置**:
- **輸入長度**: 1K, 10K, 32K, 64K, 96K, 128K (可在腳本中調整)
- **輸出長度**: 500 tokens (固定)
- **並發數**: 1, 2, 5, 10, 20 users
- **總測試點**: 6 × 5 = 30 個測試

**測試指標**:
- 吞吐量 (Throughput)
- 首 Token 時間 (TTFT - Time to First Token)
- 每 Token 時間 (TPOT - Time per Output Token)

### 2. Scaling 測試
測試系統處理不同請求數量的擴展性能力

**測試配置**:
- **輸入長度**: 1K (1024 tokens, 固定)
- **輸出長度**: 128 tokens (固定)
- **請求數範圍**:
  - 1-1000: 詳細測試 (1-200 逐個, 200-1000 每50個)
  - 1-200: 更密集的詳細測試

### 3. 自訂測試
使用 `run_benchmark.sh` 可完全自訂測試參數

---

## 🚀 快速開始

### 步驟 1: 啟動 Docker 環境

```bash
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 確認容器狀態
docker compose -f docker-compose.bench.yml ps
```

### 步驟 2: 啟動 vLLM 服務器

**終端 1** - 服務器端：

```bash
# 進入服務器容器
docker exec -it vllm-server bash

# 啟動 vLLM 服務器（120B 大模型）
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager

# 或啟動小模型進行測試
vllm serve facebook/opt-125m \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager
```

**重要提示**:
- `--enforce-eager` 是 AMD GPU 必需的參數
- 不建議手動設置 `--dtype` 和 `--max-model-len`，讓 vLLM 自動偵測
- `--tensor-parallel-size` 應設為使用的 GPU 數量

### 步驟 3: 運行基準測試

**終端 2** - 客戶端：

#### 選項 A: Production 測試（推薦）

測試多種 context length 和並發數組合：

```bash
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_production_bench.sh
```

**執行時間**: 約 30-60 分鐘（取決於模型大小和硬體）
**生成文件**: `bench_results/production/input_{length}_n{concurrency}_{timestamp}.json`

#### 選項 B: Scaling 測試

測試請求數擴展性：

```bash
# 測試 1-1000 請求數範圍（預設使用 gpt-oss-120b）
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench.sh

# 測試 1-200 請求數範圍（更密集，預設使用 gpt-oss-120b）
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench_200.sh

# 指定不同模型進行測試
docker exec vllm-bench-client bash -c "cd /root && /root/benchmark_tests/scripts/run_scaling_bench_200.sh --model google/gemma-3-4b-it"
docker exec vllm-bench-client bash -c "cd /root && /root/benchmark_tests/scripts/run_scaling_bench_200.sh --model meta-llama/Llama-3.1-8B"
docker exec vllm-bench-client bash -c "cd /root && /root/benchmark_tests/scripts/run_scaling_bench_200.sh --model Qwen/Qwen3-8B"
```

**執行時間**: 約 1-3 小時
**生成文件**: `bench_results/scaling/{model_name}/{model_name}_scale_n{num_prompts}_{timestamp}.json`

#### 選項 C: 自訂測試

```bash
# 進入客戶端容器
docker exec -it vllm-bench-client bash

# 查看完整參數說明
/root/benchmark_tests/scripts/run_benchmark.sh --help

# 範例：測試單一並發數
/root/benchmark_tests/scripts/run_benchmark.sh --single 8

# 範例：自訂輸入輸出長度
/root/benchmark_tests/scripts/run_benchmark.sh \
  --input-len 2048 \
  --output-len 256 \
  --min-concurrency 1 \
  --max-concurrency 10
```

### 步驟 4: 生成性能圖表

在**主機端**運行繪圖腳本（不需進入容器）：

```bash
cd benchmark_tests/plot_scripts

# Production 測試圖表
./run_comprehensive_plot.sh      # 綜合報告（吞吐量、TTFT、TPOT 三合一）
./run_normalized_plot.sh          # 標準化報告（相對基準性能）

# Scaling 測試圖表
./run_scaling_plot.sh             # 1-1000 範圍
./run_scaling_plot_200.sh         # 1-200 範圍
```

**生成位置**: `output_plots/` 目錄

### 步驟 5: 查看結果

```bash
# 查看測試結果文件
ls -lh bench_results/production/*.json
ls -lh bench_results/scaling/*.json

# 查看生成的圖表
ls -lh output_plots/*.png

# 美化 JSON 輸出
python3 -m json.tool bench_results/production/input_10K_n5_*.json
```

---

## 📊 數據流與架構

### 工作流程

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 啟動環境                                                  │
│    docker compose up -d                                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. 啟動 vLLM Server (容器內)                                │
│    vllm serve <model> --tensor-parallel-size 4 ...          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. 運行測試 (vllm-bench-client 容器)                        │
│    run_production_bench.sh / run_scaling_bench.sh           │
│    │                                                         │
│    ├─→ 發送並發請求到 vllm-server:8000                      │
│    ├─→ 收集性能指標                                         │
│    └─→ 保存到 bench_results/*.json                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. 生成圖表 (主機端)                                        │
│    run_comprehensive_plot.sh / run_scaling_plot.sh          │
│    │                                                         │
│    ├─→ 讀取 bench_results/*.json                            │
│    ├─→ 使用 Docker 運行 Python/matplotlib                   │
│    └─→ 生成 output_plots/*.png                              │
└─────────────────────────────────────────────────────────────┘
```

### 系統架構

```
┌────────────────────────────────────────────────────────────────┐
│  主機 (Host Machine)                                            │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  vllm-bench-client (Container)                           │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │ Benchmark Scripts                                  │  │ │
│  │  │ - run_production_bench.sh                          │  │ │
│  │  │ - run_scaling_bench.sh                             │  │ │
│  │  │ - run_benchmark.sh                                 │  │ │
│  │  │                                                     │  │ │
│  │  │ vllm bench serve --backend openai ...              │  │ │
│  │  └─────────────────┬──────────────────────────────────┘  │ │
│  └────────────────────┼─────────────────────────────────────┘ │
│                       │ HTTP Requests                         │
│                       │ (vllm-network bridge)                 │
│  ┌────────────────────▼─────────────────────────────────────┐ │
│  │  vllm-server (Container)                                 │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │ vLLM API Server                                    │  │ │
│  │  │ - Port 8000                                        │  │ │
│  │  │ - OpenAI Compatible API                            │  │ │
│  │  │ - AMD GPU Access (ROCm)                            │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  📁 Shared Volumes:                                            │
│  ├─ ~/.cache/huggingface  → Model cache                       │
│  ├─ benchmark_tests/scripts → Test scripts                    │
│  └─ bench_results          → Test results (JSON)              │
│                                                                │
│  🖥️  Host-side Tools:                                          │
│  └─ benchmark_tests/plot_scripts → Chart generation (PNG)     │
│                                                                │
│  🔧 GPU Hardware:                                              │
│  └─ /dev/kfd, /dev/dri → AMD ROCm GPU devices                 │
└────────────────────────────────────────────────────────────────┘
```

---

## 📋 常用命令參考

### Docker 容器管理

```bash
# 啟動容器（從 docker_setup 目錄）
cd docker_setup
docker compose -f docker-compose.bench.yml up -d

# 查看容器狀態
docker compose -f docker-compose.bench.yml ps

# 查看日誌
docker compose -f docker-compose.bench.yml logs -f vllm-server
docker compose -f docker-compose.bench.yml logs -f vllm-bench-client

# 停止容器
docker compose -f docker-compose.bench.yml stop

# 刪除容器
docker compose -f docker-compose.bench.yml down

# 重啟容器
docker compose -f docker-compose.bench.yml restart
```

### 進入容器

```bash
# 進入服務器容器
docker exec -it vllm-server bash

# 進入客戶端容器
docker exec -it vllm-bench-client bash
```

### vLLM 服務器操作

```bash
# 在服務器容器內啟動 vLLM
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager

# 檢查服務器狀態（從客戶端容器或主機）
curl http://localhost:8000/health
curl http://vllm-server:8000/v1/models

# 監控 GPU 使用（在服務器容器內）
watch -n 1 rocm-smi
```

### 推論測試命令

```bash
# Production 測試（在主機端執行）
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_production_bench.sh

# Scaling 測試（預設模型）
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench.sh
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench_200.sh

# Scaling 測試（指定模型）
docker exec vllm-bench-client bash -c "cd /root && /root/benchmark_tests/scripts/run_scaling_bench_200.sh --model google/gemma-3-4b-it"
docker exec vllm-bench-client bash -c "cd /root && /root/benchmark_tests/scripts/run_scaling_bench_200.sh --model Qwen/Qwen3-8B"

# 自訂測試（進入容器後執行）
docker exec -it vllm-bench-client bash
/root/benchmark_tests/scripts/run_benchmark.sh --single 8
```

### 生成圖表命令

```bash
# 在主機端執行（需在專案根目錄）
cd benchmark_tests/plot_scripts

# Production 測試圖表
./run_comprehensive_plot.sh      # 綜合報告
./run_normalized_plot.sh          # 標準化報告

# Scaling 測試圖表
./run_scaling_plot.sh             # 1-1000 範圍
./run_scaling_plot_200.sh         # 1-200 範圍
```

### 結果查看與管理

```bash
# 查看最近的測試結果
ls -lt bench_results/production/*.json | head -10
ls -lt bench_results/scaling/*.json | head -10

# 查看生成的圖表
ls -lh output_plots/*.png

# 美化 JSON 輸出
python3 -m json.tool bench_results/production/input_10K_n5_*.json | less

# 清理舊結果（謹慎使用）
rm -rf bench_results/production/*.json
rm -rf bench_results/scaling/*.json
rm -rf output_plots/*.png
```

---

## ⚙️ 配置說明

### Production 測試配置

編輯 [benchmark_tests/scripts/run_production_bench.sh](benchmark_tests/scripts/run_production_bench.sh):

```bash
# 並發數級別（第 22 行）
NUM_PROMPTS_LEVELS=(1 2 5 10 20)

# 輸入長度配置（第 27-34 行）
INPUT_CONFIGS=(
    "1024:1K"
    "10240:10K"
    "32768:32K"
    "65536:64K"
    "98304:96K"
    "131072:128K"
)

# 輸出長度（第 23 行）
OUTPUT_LEN=500
```

### Scaling 測試配置

編輯 [benchmark_tests/scripts/run_scaling_bench.sh](benchmark_tests/scripts/run_scaling_bench.sh):

```bash
# 輸入長度（第 23-24 行）
INPUT_LEN=1024
INPUT_LABEL="1K"

# 輸出長度（第 25 行）
OUTPUT_LEN=128

# 請求數測試點（第 29 行）
NUM_PROMPTS_LEVELS=(1 2 3 4 ... 200 250 300 ... 1000)
```

### vLLM 服務器參數

| 參數 | 說明 | 推薦值 |
|------|------|--------|
| `--tensor-parallel-size` | GPU 數量 | 根據模型大小：4 (120B), 1 (小模型) |
| `--gpu-memory-utilization` | GPU 記憶體使用率 | 0.9 (90%) |
| `--enforce-eager` | AMD GPU 必需 | 必須包含 |
| `--dtype` | 資料類型 | 不設定（自動偵測） |
| `--max-model-len` | 最大上下文長度 | 不設定（自動偵測） |

---

## 💡 實用技巧

### 1. 測試前檢查

```bash
# 檢查服務器是否啟動
curl http://localhost:8000/health

# 檢查 GPU 狀態
docker exec vllm-server rocm-smi

# 檢查網路連接（從客戶端）
docker exec vllm-bench-client curl http://vllm-server:8000/health
```

### 2. 監控測試進度

```bash
# 即時查看客戶端日誌
docker logs -f vllm-bench-client

# 即時查看服務器日誌
docker logs -f vllm-server

# 監控 GPU 使用（服務器容器內）
docker exec -it vllm-server bash
watch -n 1 rocm-smi
```

### 3. 結果分析技巧

```bash
# 統計某個配置的測試數量
ls bench_results/production/input_10K_* | wc -l

# 查找特定並發數的結果
ls bench_results/production/input_*_n5_*.json

# 提取關鍵指標（使用 jq）
cat bench_results/production/input_10K_n5_*.json | \
  jq '{throughput: .throughput, ttft: .ttft, tpot: .tpot}'
```

### 4. 測試最佳實踐

1. **從小到大測試**: 先用小模型驗證環境，再測大模型
2. **段落式測試**: 不要一次運行所有測試，分段進行避免問題累積
3. **保留日誌**: 保存測試日誌以便後續問題排查
4. **定期清理**: 測試前清理舊結果避免混淆

```bash
# 保存測試日誌範例
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_production_bench.sh \
  2>&1 | tee production_test_$(date +%Y%m%d_%H%M%S).log
```

---

## 🔍 故障排查

### 問題 1: 容器無法啟動

**症狀**: `docker compose up -d` 失敗

**檢查方式**:
```bash
# 查看詳細日誌
docker compose -f docker_setup/docker-compose.bench.yml logs

# 檢查 GPU 設備
ls -l /dev/kfd /dev/dri

# 檢查 Docker 版本
docker compose version
```

**常見原因**:
- GPU 設備權限問題 → 加入 `video` 群組
- Docker Compose 版本過舊 → 升級到 2.0+
- 端口 8000 被占用 → 修改 docker-compose.yml 端口映射

### 問題 2: vLLM 服務器啟動失敗

**症狀**: 服務器容器內 `vllm serve` 命令失敗

**檢查方式**:
```bash
# 查看詳細錯誤
docker logs vllm-server

# 檢查 GPU 可用性
docker exec vllm-server rocm-smi
docker exec vllm-server rocminfo

# 檢查模型是否下載
docker exec vllm-server ls -lh /root/.cache/huggingface/hub/
```

**常見原因**:
- **GPU 記憶體不足**: 降低 `--gpu-memory-utilization` 或使用更小的模型
- **模型未下載**: 等待模型下載完成（首次需要較長時間）
- **ROCm 版本不相容**: 確認使用正確的 Docker 映像

**解決方案**:
```bash
# GPU 記憶體不足
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.7 \  # 降低到 70%
  --enforce-eager

# 使用小模型測試
vllm serve facebook/opt-125m \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager
```

### 問題 3: 客戶端無法連接服務器

**症狀**: 測試腳本報錯 "無法連接到 vLLM 服務器"

**檢查方式**:
```bash
# 檢查服務器健康狀態
docker exec vllm-bench-client curl http://vllm-server:8000/health

# 檢查網路連接
docker network inspect docker_setup_vllm-network

# 檢查服務器是否在監聽
docker exec vllm-server netstat -tulpn | grep 8000
```

**常見原因**:
- vLLM 服務器未啟動或啟動失敗
- 網路配置錯誤
- 容器名稱不匹配

### 問題 4: 測試結果未生成

**症狀**: 測試完成但找不到 JSON 文件

**檢查方式**:
```bash
# 查看測試腳本輸出
docker logs vllm-bench-client

# 檢查結果目錄
docker exec vllm-bench-client ls -lh /root/bench_results/production/
docker exec vllm-bench-client ls -lh /root/bench_results/scaling/

# 查看當前目錄是否有殘留文件
docker exec vllm-bench-client ls -lh /root/*.json
```

**常見原因**:
- 測試未完成（被中斷）
- 結果目錄權限問題
- vllm bench 命令失敗

**解決方案**:
```bash
# 確保結果目錄存在且有權限
docker exec vllm-bench-client mkdir -p /root/bench_results/production
docker exec vllm-bench-client chmod 777 /root/bench_results/production

# 查看測試退出代碼（在腳本輸出中）
# 退出代碼應為 0
```

### 問題 5: 圖表生成失敗

**症狀**: `run_comprehensive_plot.sh` 等腳本執行失敗

**檢查方式**:
```bash
# 檢查測試結果是否存在
ls -lh bench_results/production/*.json
ls -lh bench_results/scaling/*.json

# 檢查 Docker 是否可用
docker ps

# 手動測試 Python 環境
docker run --rm python:3.11-slim python3 --version
```

**常見原因**:
- 測試結果文件不存在或路徑錯誤
- Docker 無法運行
- Python 腳本語法錯誤

**解決方案**:
```bash
# 確保在正確的目錄執行
cd /home/user/vllm_t/benchmark_tests/plot_scripts
pwd  # 應輸出 /home/user/vllm_t/benchmark_tests/plot_scripts

# 檢查測試結果路徑
ls -l ../../bench_results/production/

# 查看詳細錯誤信息
./run_comprehensive_plot.sh 2>&1 | tee plot_error.log
```

### 問題 6: 上下文長度超出限制

**症狀**: 測試報錯 "maximum context length is XXX tokens"

**原因**: `input_len + output_len` 超過模型支持的最大長度

**解決方案**:
```bash
# 方案 1: 調整測試參數（在測試腳本中修改）
# 確保 input_len + output_len < max_model_len

# 方案 2: 啟動服務器時設置更大的上下文（不推薦）
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.7 \
  --max-model-len 4096 \
  --enforce-eager
```

### 問題 7: 特定模型無法載入

**症狀**: Ministral 3 14B Instruct 報錯 "Tokenizer class TokenizersBackend does not exist"

**錯誤訊息**:
```
ValueError: Tokenizer class TokenizersBackend does not exist or is not currently imported.
RuntimeError: Failed to load the tokenizer.
```

**原因**:
- Ministral 3 14B 模型需要 vLLM 0.12.0 或更新版本
- 當前使用的 ROCm 官方映像 `rocm/vllm:rocm7.0.0_vllm_0.10.2_20251006` 僅支援 vLLM 0.10.2
- ROCm 官方尚未提供包含 vLLM 0.12.0 的映像檔

**解決方案**:
- **暫時無法解決**: 等待 ROCm 官方發布包含 vLLM 0.12.0+ 的新映像
- **替代方案**: 使用其他已測試成功的模型：
  - `google/gemma-3-4b-it` - 輕量級，適合快速測試
  - `meta-llama/Llama-3.1-8B` - Meta 官方模型
  - `Qwen/Qwen3-8B` - 阿里通義千問模型
  - `openai/gpt-oss-120b` - 大型模型（需 4 GPU）

**檢查 vLLM 版本**:
```bash
docker exec vllm-server vllm --version
# 輸出: vllm 0.10.2
```

---

## 📚 詳細文檔

- **[docker_setup/README.md](docker_setup/README.md)** - Docker 環境配置詳細說明
  - 容器配置
  - 網路設置
  - 故障排除

- **[docs/](docs/)** - 其他文檔
  - `troubleshooting/` - 歷史故障排除記錄
  - `archive/` - 舊版文檔存檔

---

## 📈 測試結果示例

### Production 測試結果

生成文件格式: `input_{length}_n{concurrency}_{timestamp}.json`

範例:
```
bench_results/production/
├── input_1K_n1_20251114_120000.json
├── input_1K_n2_20251114_120100.json
├── input_1K_n5_20251114_120200.json
├── input_10K_n1_20251114_120300.json
├── input_10K_n2_20251114_120400.json
└── ...
```

### Scaling 測試結果

生成文件格式: `scale_n{num_prompts}_{timestamp}.json`

範例:
```
bench_results/scaling/
├── scale_n1_20251114_130000.json
├── scale_n2_20251114_130010.json
├── scale_n5_20251114_130020.json
├── scale_n10_20251114_130030.json
└── ...
```

### 圖表輸出

```
output_plots/
├── benchmark_comprehensive.png      # 綜合報告（吞吐量、TTFT、TPOT）
├── benchmark_normalized.png         # 標準化報告
├── scaling_benchmark.png            # 擴展性（1-1000）
└── scaling_benchmark_200.png        # 擴展性（1-200）
```

---

## ⚠️ 注意事項

1. **GPU 記憶體管理**
   - 120B 模型需要 4 個 GPU 且每個有足夠 VRAM
   - 建議先用小模型（如 opt-125m）驗證環境

2. **測試時間規劃**
   - Production 完整測試需 30-60 分鐘
   - Scaling 完整測試需 1-3 小時
   - 建議使用 `screen` 或 `tmux` 避免連線中斷

3. **結果管理**
   - 測試結果自動保存到 `bench_results/`
   - `.gitignore` 已設定忽略結果文件
   - 定期清理避免磁碟空間不足

4. **Docker 版本**
   - 使用 `docker compose`（v2）而非 `docker-compose`（v1）
   - Compose 檔案已移除 `version` 欄位（v2 標準）

---

## 🚀 完整工作流程範例

以下是從零開始的完整測試流程：

```bash
# ========================================
# 階段 1: 環境準備
# ========================================

# 啟動 Docker 環境
cd /home/user/vllm_t/docker_setup
docker compose -f docker-compose.bench.yml up -d

# 確認容器運行
docker ps | grep vllm

# ========================================
# 階段 2: 啟動 vLLM 服務器（終端 1）
# ========================================

# 進入服務器容器
docker exec -it vllm-server bash

# 啟動 vLLM（120B 大模型）
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager

# 等待服務器啟動完成（看到 "Application startup complete"）

# ========================================
# 階段 3: 運行測試（終端 2）
# ========================================

# 檢查服務器狀態
curl http://localhost:8000/health

# 運行 Production 測試
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_production_bench.sh

# 等待測試完成（約 30-60 分鐘）

# ========================================
# 階段 4: 生成圖表（主機端）
# ========================================

cd /home/user/vllm_t/benchmark_tests/plot_scripts

# 生成所有圖表
./run_comprehensive_plot.sh
./run_normalized_plot.sh

# ========================================
# 階段 5: 查看結果
# ========================================

# 查看測試結果
ls -lh ../../bench_results/production/

# 查看圖表
ls -lh ../../output_plots/

# 分析特定結果
python3 -m json.tool ../../bench_results/production/input_10K_n5_*.json

# ========================================
# 階段 6: 清理（可選）
# ========================================

# 停止容器
cd /home/user/vllm_t/docker_setup
docker compose -f docker-compose.bench.yml stop

# 或完全移除容器
docker compose -f docker-compose.bench.yml down
```

---

## 📞 支援與反饋

如有問題或建議，請參考：

1. **故障排查章節**: 查看上方「🔍 故障排查」
2. **文檔目錄**: 查看 `docs/` 目錄中的詳細文檔
3. **日誌分析**: 使用 `docker logs` 查看詳細錯誤信息

---

**🎉 開始您的 vLLM 性能測試之旅！**
