# vLLM 測試執行指南

## 🎯 測試流程概覽

```
啟動 vLLM Server → 執行 Benchmark 測試 → 收集結果
   (終端 1)              (終端 2)            (JSON 文件)
```

---

## 📍 步驟 1: 啟動 vLLM 服務器

### 開啟終端 1 - 服務器端

```bash
# 進入服務器容器
docker exec -it vllm-server bash

# 啟動 vLLM 服務器（120B 大模型）
vllm serve openai/gpt-oss-120b \
  --tensor-parallel-size 4 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager
```

### 啟動參數說明

| 參數 | 說明 | 值 |
|------|------|-----|
| `openai/gpt-oss-120b` | 模型名稱 | 可替換為其他模型 |
| `--tensor-parallel-size` | GPU 數量 | 4 (120B 模型需要) |
| `--gpu-memory-utilization` | GPU 記憶體使用率 | 0.9 (90%) |
| `--enforce-eager` | AMD GPU 必需參數 | 固定參數 |

### 服務器啟動成功標誌

等待看到以下訊息：
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 小模型測試（可選）

如果要快速驗證環境，可以使用小模型：

```bash
vllm serve facebook/opt-125m \
  --tensor-parallel-size 1 \
  --gpu-memory-utilization 0.9 \
  --enforce-eager
```

---

## 📍 步驟 2: 驗證服務器狀態

### 開啟終端 2 - 客戶端

在**另一個終端**執行：

```bash
# 檢查服務器健康狀態
curl http://localhost:8000/health

# 預期輸出
# 狀態碼 200，無錯誤訊息
```

```bash
# 檢查已載入的模型
curl http://localhost:8000/v1/models

# 預期輸出 (JSON)
{
  "object": "list",
  "data": [
    {
      "id": "openai/gpt-oss-120b",
      "object": "model",
      ...
    }
  ]
}
```

---

## 📍 步驟 3: 執行基準測試

保持**終端 1 的 vLLM 服務器運行**，在**終端 2**執行測試。

### 測試選項 A: Production 測試（推薦）

測試多種輸入長度和並發數組合：

```bash
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_production_bench.sh
```

**測試配置**:
- 輸入長度: 1K, 2K, 4K, 8K, 10K, 32K, 64K, 96K
- 輸出長度: 500 tokens
- 並發數: 1, 2, 5, 10, 20
- 總測試數: 8 × 5 = 40 個測試點

**預估時間**: 30-60 分鐘

**輸出示例**:
```
========================================
vLLM Production Benchmark
========================================

服务器: http://vllm-server:8000
模型: openai/gpt-oss-120b
Num Prompts 级别: 1 2 5 10 20
输出长度: 500 tokens
...

========================================
测试 [1/40]
Input: 1K | Num Prompts: 1
========================================

✓ 结果已保存: /root/bench_results/production/input_1K_n1_20251114_120000.json
```

### 測試選項 B: Scaling 測試

測試系統處理不同請求數量的能力：

```bash
# 測試 1-1000 請求數範圍
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench.sh

# 或測試 1-200 請求數範圍（更密集）
docker exec vllm-bench-client bash /root/benchmark_tests/scripts/run_scaling_bench_200.sh
```

**測試配置**:
- 輸入長度: 1K (固定)
- 輸出長度: 128 tokens (固定)
- 請求數: 1-200 或 1-1000

**預估時間**: 1-3 小時

### 測試選項 C: 自訂測試

進入客戶端容器進行自訂測試：

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
  --max-concurrency 5
```

---

## 📊 步驟 4: 測試結果

### 結果文件位置

```bash
# Production 測試結果
ls -lh bench_results/production/

# Scaling 測試結果
ls -lh bench_results/scaling/
```

### 結果文件格式

**Production 測試**:
```
bench_results/production/
├── input_1K_n1_20251114_120000.json
├── input_1K_n2_20251114_120100.json
├── input_1K_n5_20251114_120200.json
├── input_2K_n1_20251114_120300.json
└── ...
```

**Scaling 測試**:
```
bench_results/scaling/
├── scale_n1_20251114_130000.json
├── scale_n2_20251114_130010.json
├── scale_n5_20251114_130020.json
└── ...
```

### 查看結果內容

```bash
# 美化 JSON 輸出
python3 -m json.tool bench_results/production/input_1K_n1_*.json

# 主要指標
{
  "throughput": 123.45,           # 吞吐量 (requests/s)
  "mean_ttft_ms": 45.67,          # 平均首 Token 時間 (ms)
  "mean_tpot_ms": 12.34,          # 平均每 Token 時間 (ms)
  "mean_latency_ms": 567.89,      # 平均延遲 (ms)
  ...
}
```

---

## 🔄 監控測試進度

### 即時查看客戶端日誌

```bash
docker logs -f vllm-bench-client
```

### 即時查看服務器日誌

```bash
docker logs -f vllm-server
```

### 監控 GPU 使用

在**終端 1**（服務器容器內）：

```bash
# 每秒更新一次 GPU 狀態
watch -n 1 rocm-smi
```

---

## ⚠️ 測試注意事項

### 1. 上下文長度限制

確保 `input_len + output_len < max_model_len`

**錯誤示例**:
```
Error: maximum context length is 2048 tokens
```

**解決方案**: 調整測試參數或增加 `--max-model-len`

### 2. 測試中斷處理

如果測試中斷：
- **不要重複啟動**: 檢查是否有殘留進程
- **清理臨時文件**: `docker exec vllm-bench-client rm /root/*.json`
- **重新開始**: 從中斷點繼續或完全重新測試

### 3. 結果文件未生成

**檢查步驟**:
```bash
# 1. 查看測試腳本輸出（尋找錯誤訊息）
docker logs vllm-bench-client | tail -100

# 2. 檢查結果目錄
docker exec vllm-bench-client ls -lh /root/bench_results/production/

# 3. 查看 vllm bench 退出代碼（應為 0）
# 在測試輸出中尋找: "基準測試退出代碼: 0"
```

### 4. 測試時間過長

**優化建議**:
- 減少測試點數量（修改腳本中的 `INPUT_CONFIGS` 和 `NUM_PROMPTS_LEVELS`）
- 使用小模型快速驗證
- 分批執行測試

---

## ✅ 測試完成檢查清單

- [ ] vLLM 服務器成功啟動並保持運行
- [ ] 測試腳本執行完成（無錯誤）
- [ ] 結果文件已生成在 `bench_results/` 目錄
- [ ] 結果 JSON 文件包含完整指標數據
- [ ] 記錄測試配置和時間戳

**✓ 測試執行完成，可以進行下一步：生成性能圖表**
