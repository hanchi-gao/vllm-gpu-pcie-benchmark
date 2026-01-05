#!/bin/bash
# Run All Tests for Machine C (Separate Hardware)
# 機器 C 在獨立硬體上，執行所有 Config C 的測試

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_SCRIPT="${SCRIPT_DIR}/run_pcie_benchmark.sh"

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Machine C - PCIe Bandwidth Test Suite             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script runs all tests for configuration C${NC}"
echo -e "${YELLOW}Total: 4 tests across 4 groups${NC}"
echo ""

# 測試統計
TOTAL_TESTS=4
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_TEST_IDS=()

# ============================================================
# Group 1: 7B + TP=1 (Config C: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 1: 7B Model + TP=1 (Config C)                      ║${NC}"
echo -e "${CYAN}║  Tests: 1C-1k                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve meta-llama/Llama-3.1-8B \\"
echo "    --tensor-parallel-size 1 \\"
echo "    --gpu-memory-utilization 0.9 \\"
echo "    --max-model-len 1280 \\"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is ready, or Ctrl+C to cancel..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config C --model 7B --tp 1 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("1C-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 1 completed! (1/4 tests)${NC}"
echo ""

# ============================================================
# Group 2: 7B + TP=2 (Config C: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 2: 7B Model + TP=2 (Config C)                      ║${NC}"
echo -e "${CYAN}║  Tests: 2C-1k                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve meta-llama/Llama-3.1-8B \\"
echo "    --tensor-parallel-size 2 \\"
echo "    --gpu-memory-utilization 0.9 \\"
echo "    --max-model-len 1280 \\"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with TP=2..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config C --model 7B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("2C-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 2 completed! (2/4 tests)${NC}"
echo ""

# ============================================================
# Group 3: 14B + TP=2 (Config C: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 3: 14B Model + TP=2 (Config C)                     ║${NC}"
echo -e "${CYAN}║  Tests: 3C-1k                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve Qwen/Qwen3-14B \\"
echo "    --tensor-parallel-size 2 \\"
echo "    --gpu-memory-utilization 0.9 \\"
echo "    --max-model-len 1280 \\"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with 14B model..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config C --model 14B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("3C-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 3 completed! (3/4 tests)${NC}"
echo ""

# ============================================================
# Group 4: 30B + TP=2 (Config C: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 4: 30B Model + TP=2 (Config C)                     ║${NC}"
echo -e "${CYAN}║  Tests: 4C-1k                                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve google/gemma-3-27b-it \\"
echo "    --tensor-parallel-size 2 \\"
echo "    --gpu-memory-utilization 0.9 \\"
echo "    --max-model-len 1280 \\"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with 30B model..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config C --model 30B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("4C-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 4 completed! (4/4 tests)${NC}"
echo ""

# ============================================================
# Final Summary
# ============================================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Machine C Test Suite - Summary                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Total Tests:   ${TOTAL_TESTS}${NC}"
echo -e "${GREEN}Passed:        ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed:        ${FAILED_TESTS}${NC}"
echo ""

if [[ ${#FAILED_TEST_IDS[@]} -gt 0 ]]; then
    echo -e "${RED}Failed Test IDs:${NC}"
    for test_id in "${FAILED_TEST_IDS[@]}"; do
        echo -e "  ${RED}✗ ${test_id}${NC}"
    done
    echo ""
    echo -e "${YELLOW}Results saved to: bench_results/pcie/${NC}"
    exit 1
else
    echo -e "${GREEN}✓ All tests completed successfully! 🎉${NC}"
    echo ""
    echo -e "${YELLOW}Results saved to: bench_results/pcie/${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "  1. Copy bench_results/pcie/ from Machine C"
    echo -e "  2. Merge with results from Machine A/B"
    echo -e "  3. Analyze combined results"
    exit 0
fi
