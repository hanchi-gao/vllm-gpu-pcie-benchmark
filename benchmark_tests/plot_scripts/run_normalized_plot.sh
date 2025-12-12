#!/bin/bash

#######################################
# 生成標準化 benchmark 報告
#
# 用法:
#   ./run_normalized_plot.sh
#######################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

RESULTS_PATH="/data/bench_results/production"
OUTPUT_FILE="benchmark_normalized.png"

echo "啟動標準化報告生成..."
echo "項目目錄: $PROJECT_DIR"
echo "結果路徑: $RESULTS_PATH"
echo "輸出文件: output_plots/$OUTPUT_FILE"
echo

# 確保輸出目錄存在
mkdir -p "$PROJECT_DIR/output_plots"

docker run --rm \
    -v "$PROJECT_DIR/bench_results:/data/bench_results:ro" \
    -v "$SCRIPT_DIR:/plot_scripts:ro" \
    -v "$PROJECT_DIR/output_plots:/output" \
    -w /output \
    python:3.11-slim \
    bash -c "
        pip install matplotlib --quiet && \
        python3 /plot_scripts/plot_normalized_benchmark.py \
            --results-dir $RESULTS_PATH \
            --output /output/$OUTPUT_FILE
    "

if [ $? -eq 0 ]; then
    echo
    echo "✓ 完成！標準化報告已保存到: $PROJECT_DIR/output_plots/$OUTPUT_FILE"
else
    echo
    echo "✗ 生成失敗"
    exit 1
fi
