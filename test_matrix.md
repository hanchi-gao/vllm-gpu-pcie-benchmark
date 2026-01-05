# PCIe Bandwidth Impact Test Matrix

## 硬體配置定義

| 配置代號 | 描述 | PCIe 配置 | GPU 數量 | 單卡頻寬 | 機器位置 | 測試數量 |
|---------|------|-----------|---------|---------|---------|---------|
| **A** | 消費型主板單卡 | 1×x16 | 1 | 32 GB/s | 機器 A/B | 5 個 |
| **B** | 雙卡 x8 配置 | 2×x8 | 2 | 16 GB/s | 機器 A/B | 12 個 |
| **C** | 四卡機雙卡 | 2×x16 | 2 | 32 GB/s | 機器 C | 12 個 |

**重要**:
- 配置 A 和 B 在**同一台機器**上（共 17 個測試）
- 配置 C 在**獨立機器**上（12 個測試）
- 總計 29 個測試（17 + 12）

## 模型配置

| 模型大小 | 完整模型名稱 | 參數量 | 最小 GPU 需求 |
|---------|-------------|-------|--------------|
| 7B | `meta-llama/Llama-3.1-8B` | ~8B | 1 GPU |
| 13B | `meta-llama/Llama-2-13b-hf` | ~13B | 1-2 GPU |
| 30B | `meta-llama/Llama-2-30b-hf` | ~30B | 2 GPU (TP=2) |

## 測試參數

- **Input Length**: 1024 (1k), 2048 (2k), 4096 (4k) tokens
- **Output Length**: 128 tokens (固定)
- **Tensor Parallel**: 1 或 2
- **GPU Memory Utilization**: 0.9 (90%)

---

## 完整測試矩陣 (24 個測試)

### Group 1: 7B Model + TP=1 (9 tests)

測試單卡性能在不同 PCIe 配置下的表現

| Test ID | 配置 | 模型 | TP | Input | Output | 命令 |
|---------|------|------|----|-------|--------|------|
| 1A-1k | A | 7B | 1 | 1024 | 128 | `./run_pcie_benchmark.sh --config A --model 7B --tp 1 --input-len 1024` |
| 1A-2k | A | 7B | 1 | 2048 | 128 | `./run_pcie_benchmark.sh --config A --model 7B --tp 1 --input-len 2048` |
| 1A-4k | A | 7B | 1 | 4096 | 128 | `./run_pcie_benchmark.sh --config A --model 7B --tp 1 --input-len 4096` |
| 1B-1k | B | 7B | 1 | 1024 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 1 --input-len 1024` |
| 1B-2k | B | 7B | 1 | 2048 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 1 --input-len 2048` |
| 1B-4k | B | 7B | 1 | 4096 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 1 --input-len 4096` |
| 1C-1k | C | 7B | 1 | 1024 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 1 --input-len 1024` |
| 1C-2k | C | 7B | 1 | 2048 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 1 --input-len 2048` |
| 1C-4k | C | 7B | 1 | 4096 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 1 --input-len 4096` |

**vLLM Server 命令**:
```bash
vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 1 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

---

### Group 2: 7B Model + TP=2 (6 tests)

測試 Tensor Parallel 通訊在不同 PCIe 頻寬下的影響

| Test ID | 配置 | 模型 | TP | Input | Output | 命令 |
|---------|------|------|----|-------|--------|------|
| 2B-1k | B | 7B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 2 --input-len 1024` |
| 2B-2k | B | 7B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 2 --input-len 2048` |
| 2B-4k | B | 7B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config B --model 7B --tp 2 --input-len 4096` |
| 2C-1k | C | 7B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 2 --input-len 1024` |
| 2C-2k | C | 7B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 2 --input-len 2048` |
| 2C-4k | C | 7B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config C --model 7B --tp 2 --input-len 4096` |

**vLLM Server 命令**:
```bash
vllm serve meta-llama/Llama-3.1-8B --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

---

### Group 3: 13B Model + TP=1 (2 tests)

測試 VRAM 緊繃情況下的性能

| Test ID | 配置 | 模型 | TP | Input | Output | 命令 |
|---------|------|------|----|-------|--------|------|
| 3A-1k | A | 13B | 1 | 1024 | 128 | `./run_pcie_benchmark.sh --config A --model 13B --tp 1 --input-len 1024` |
| 3A-2k | A | 13B | 1 | 2048 | 128 | `./run_pcie_benchmark.sh --config A --model 13B --tp 1 --input-len 2048` |

**vLLM Server 命令**:
```bash
vllm serve meta-llama/Llama-2-13b-hf --tensor-parallel-size 1 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

**注意**: 可能接近 VRAM 上限，若失敗可降低 `--gpu-memory-utilization` 到 0.7

---

### Group 4: 13B Model + TP=2 (6 tests)

測試中型模型在雙卡配置下的性能

| Test ID | 配置 | 模型 | TP | Input | Output | 命令 |
|---------|------|------|----|-------|--------|------|
| 3B-1k | B | 13B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config B --model 13B --tp 2 --input-len 1024` |
| 3B-2k | B | 13B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config B --model 13B --tp 2 --input-len 2048` |
| 3B-4k | B | 13B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config B --model 13B --tp 2 --input-len 4096` |
| 3C-1k | C | 13B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config C --model 13B --tp 2 --input-len 1024` |
| 3C-2k | C | 13B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config C --model 13B --tp 2 --input-len 2048` |
| 3C-4k | C | 13B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config C --model 13B --tp 2 --input-len 4096` |

**vLLM Server 命令**:
```bash
vllm serve meta-llama/Llama-2-13b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

---

### Group 5: 30B Model + TP=2 (6 tests)

測試大型模型在雙卡配置下的性能差異

| Test ID | 配置 | 模型 | TP | Input | Output | 命令 |
|---------|------|------|----|-------|--------|------|
| 4B-1k | B | 30B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config B --model 30B --tp 2 --input-len 1024` |
| 4B-2k | B | 30B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config B --model 30B --tp 2 --input-len 2048` |
| 4B-4k | B | 30B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config B --model 30B --tp 2 --input-len 4096` |
| 4C-1k | C | 30B | 2 | 1024 | 128 | `./run_pcie_benchmark.sh --config C --model 30B --tp 2 --input-len 1024` |
| 4C-2k | C | 30B | 2 | 2048 | 128 | `./run_pcie_benchmark.sh --config C --model 30B --tp 2 --input-len 2048` |
| 4C-4k | C | 30B | 2 | 4096 | 128 | `./run_pcie_benchmark.sh --config C --model 30B --tp 2 --input-len 4096` |

**vLLM Server 命令**:
```bash
vllm serve meta-llama/Llama-2-30b-hf --tensor-parallel-size 2 --gpu-memory-utilization 0.9 --max-model-len 4096 --enforce-eager
```

---

## 測試重點分析

### 預期觀察指標

1. **配置 A vs B vs C (TP=1)**
   - 單卡模式下，PCIe 頻寬差異對性能的影響
   - 預期：差異較小（主要受限於 GPU 運算能力）

2. **配置 B vs C (TP=2)**
   - x8 vs x16 PCIe 頻寬對 Tensor Parallel 通訊的影響
   - 預期：配置 C (x16) 在 TP=2 時性能更好

3. **7B vs 13B vs 30B (相同配置)**
   - 不同模型大小對 PCIe 頻寬需求的差異
   - 預期：模型越大，PCIe 頻寬瓶頸越明顯

4. **Input Length 1k vs 2k vs 4k**
   - 輸入長度對性能的影響
   - 預期：輸入越長，TTFT 越高，但 TPOT 差異較小

### 關鍵性能指標

- **Throughput**: 吞吐量 (requests/s)
- **TTFT**: Time to First Token (ms) - 反映 prefill 階段性能
- **TPOT**: Time per Output Token (ms) - 反映 decode 階段性能

---

## 執行建議

1. **按組別執行**
   - 每組測試需要重啟 vLLM server
   - 建議完成一組後再進行下一組

2. **記錄硬體狀態**
   - 在每組測試前確認 PCIe 配置
   - 使用 `lspci -vv` 查看 PCIe 連接速度

3. **監控資源使用**
   - 使用 `rocm-smi` 監控 GPU 使用率和記憶體
   - 確保每次測試前 GPU 狀態乾淨

4. **結果驗證**
   - 每個測試完成後檢查結果文件
   - 確認測試元數據正確記錄

---

**總測試數**: 24 個測試
**預估總時間**: 2-4 小時（含 server 切換時間）
