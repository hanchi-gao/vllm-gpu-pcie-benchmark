#!/bin/bash
# Run All Tests for Machine A/B (Same Hardware)
# 機器 A/B 在同一台機器上，只需切換 PCIe 配置和 vLLM 參數

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
echo -e "${CYAN}║       Machine A/B - PCIe Bandwidth Test Suite             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script runs all tests for configurations A and B${NC}"
echo -e "${YELLOW}Total: 6 tests across 5 groups${NC}"
echo ""

# 測試統計
TOTAL_TESTS=6
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_TEST_IDS=()

# ============================================================
# Group 1: 7B + TP=1 (Config A + B: 2 tests)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 1: 7B Model + TP=1 (Config A + B)                  ║${NC}"
echo -e "${CYAN}║  Tests: 1A-1k, 1B-1k          ║${NC}"
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

# Config A tests
for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config A --model 7B --tp 1 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("1A-${INPUT_LABEL}")
    fi
    sleep 3
done

# Config B tests
echo -e "${YELLOW}Switch to Config B (if needed) and press Enter...${NC}"
read
for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config B --model 7B --tp 1 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("1B-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 1 completed! (2/6 tests)${NC}"
echo ""

# ============================================================
# Group 2: 7B + TP=2 (Config B only: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 2: 7B Model + TP=2 (Config B only)                 ║${NC}"
echo -e "${CYAN}║  Tests: 2B-1k                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve meta-llama/Llama-3.1-8B"
echo "    --tensor-parallel-size 2"
echo "    --gpu-memory-utilization 0.9"
echo "    --max-model-len 1280"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with TP=2..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config B --model 7B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("2B-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 2 completed! (3/6 tests)${NC}"
echo ""

# ============================================================
# Group 3: 14B + TP=1 (Config A only: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 3: 14B Model + TP=1 (Config A only)                ║${NC}"
echo -e "${CYAN}║  Tests: 3A-1k                                       ║${NC}"
echo -e "${CYAN}║  ⚠️  Warning: May be close to VRAM limit                   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve Qwen/Qwen3-14B"
echo "    --tensor-parallel-size 1"
echo "    --gpu-memory-utilization 0.9"
echo "    --max-model-len 1280"
echo "    --enforce-eager"
echo ""
echo -e "${YELLOW}Note: If VRAM insufficient, use --gpu-memory-utilization 0.7${NC}"
echo ""
read -p "Press Enter when vLLM server is restarted with 14B model..."
echo ""

# Switch back to Config A
echo -e "${YELLOW}Ensure you're on Config A and press Enter...${NC}"
read

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config A --model 14B --tp 1 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("3A-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 3 completed! (4/6 tests)${NC}"
echo ""

# ============================================================
# Group 4: 14B + TP=2 (Config B only: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 4: 14B Model + TP=2 (Config B only)                ║${NC}"
echo -e "${CYAN}║  Tests: 3B-1k                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve Qwen/Qwen3-14B"
echo "    --tensor-parallel-size 2"
echo "    --gpu-memory-utilization 0.9"
echo "    --max-model-len 1280"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with TP=2..."
echo ""

# Switch to Config B
echo -e "${YELLOW}Switch to Config B and press Enter...${NC}"
read

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config B --model 14B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("3B-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 4 completed! (5/6 tests)${NC}"
echo ""

# ============================================================
# Group 5: 30B + TP=2 (Config B only: 1 test)
# ============================================================
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Group 5: 30B Model + TP=2 (Config B only)                ║${NC}"
echo -e "${CYAN}║  Tests: 4B-1k                                ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Required vLLM Server Configuration:${NC}"
echo ""
echo "  vllm serve google/gemma-3-27b-it"
echo "    --tensor-parallel-size 2"
echo "    --gpu-memory-utilization 0.9"
echo "    --max-model-len 1280"
echo "    --enforce-eager"
echo ""
read -p "Press Enter when vLLM server is restarted with 30B model..."
echo ""

for INPUT_LEN in 1024; do
    INPUT_LABEL="${INPUT_LEN:0:1}k"
    if "$BENCHMARK_SCRIPT" --config B --model 30B --tp 2 --input-len "$INPUT_LEN"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_IDS+=("4B-${INPUT_LABEL}")
    fi
    sleep 3
done

echo -e "${GREEN}Group 5 completed! (6/6 tests)${NC}"
echo ""

# ============================================================
# Final Summary
# ============================================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Machine A/B Test Suite - Summary                 ║${NC}"
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
    echo -e "  1. Copy bench_results/pcie/ to Machine C"
    echo -e "  2. Run tests on Machine C using run_machine_C_tests.sh"
    echo -e "  3. Combine results for analysis"
    exit 0
fi
