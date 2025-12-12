# vLLM Benchmark 測試

這個目錄包含所有與 vLLM 推論基準測試相關的腳本和繪圖工具。

## 目錄結構

```
benchmark_tests/
├── scripts/                    # 基準測試腳本（容器內執行）
│   ├── run_benchmark.sh
│   ├── run_production_bench.sh
│   ├── run_scaling_bench.sh
│   └── run_scaling_bench_200.sh
│
└── plot_scripts/               # 繪圖腳本（主機端執行）
    ├── plot_benchmark_results.py
    ├── plot_comprehensive_benchmark.py
    ├── plot_normalized_benchmark.py
    ├── plot_scaling_benchmark.py
    ├── plot_scaling_benchmark_200.py
    ├── run_plot.sh
    ├── run_comprehensive_plot.sh
    ├── run_normalized_plot.sh
    ├── run_scaling_plot.sh
    └── run_scaling_plot_200.sh
```

## 使用方法

### 1. 運行基準測試

```bash
# Production 測試（多配置）
docker exec vllm-bench bash /root/benchmark_tests/scripts/run_production_bench.sh

# 擴展性測試（1-1000）
docker exec vllm-bench bash /root/benchmark_tests/scripts/run_scaling_bench.sh

# 擴展性測試（1-200）
docker exec vllm-bench bash /root/benchmark_tests/scripts/run_scaling_bench_200.sh
```

### 2. 生成圖表

```bash
cd /home/user/vllm_t/benchmark_tests/plot_scripts

# 綜合報告
./run_comprehensive_plot.sh

# 標準化報告
./run_normalized_plot.sh

# 擴展性報告
./run_scaling_plot.sh       # 1-1000 範圍
./run_scaling_plot_200.sh   # 1-200 範圍
```

## 測試配置

### Production 測試
- **輸入長度**: 1K, 10K, 32K, 64K, 96K, 128K
- **並發數**: 1, 2, 5, 10, 20
- **輸出長度**: 500 tokens

### 擴展性測試
- **輸入長度**: 1K (固定)
- **輸出長度**: 128 tokens (固定)
- **請求數**:
  - run_scaling_bench.sh: 1-200 (individual), 250-1000 (step 50)
  - run_scaling_bench_200.sh: 1-200 (all values)

## 結果位置

- **測試結果**: `/root/bench_results/` (容器內) 或 `../bench_results/` (主機)
- **生成圖表**: `../output_plots/`

## 注意事項

- 測試腳本在容器內執行
- 繪圖腳本在主機端執行（使用 Docker）
- 確保 vLLM 服務器正在運行
