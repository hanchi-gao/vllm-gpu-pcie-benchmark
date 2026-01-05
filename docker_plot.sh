#!/bin/bash
# Run plotting script inside Docker container with matplotlib installed

docker run --rm \
  -v "$(pwd)/bench_results:/data/bench_results" \
  -v "$(pwd)/plot_pcie_results.py:/app/plot_pcie_results.py" \
  -v "$(pwd):/output" \
  python:3.11-slim \
  bash -c "
    pip install matplotlib numpy --quiet && \
    cd /app && \
    python plot_pcie_results.py && \
    cp pcie_benchmark_results.png /output/
  "

echo "Plot should be saved to: pcie_benchmark_results.png"
