#!/bin/bash
# Run All PCIe Benchmark Tests
# 執行完整的 24 個測試組合

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

# 測試計數
TOTAL_TESTS=24
CURRENT_TEST=0
PASSED_TESTS=0
FAILED_TESTS=0

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       vLLM PCIe Bandwidth Impact - Full Test Suite        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Total tests to run: ${TOTAL_TESTS}${NC}"
echo ""

# 測試矩陣定義
# 格式: "CONFIG MODEL_SIZE TP_SIZE INPUT_LEN TEST_ID DESCRIPTION"
declare -a TEST_MATRIX=(
    # Group 1: Single GPU baseline tests (配置 A, B, C - TP=1)
    "A 7B 1 1024 1A-1k Single_GPU_x16_7B_baseline"
    "A 7B 1 2048 1A-2k Single_GPU_x16_7B_baseline"
    "A 7B 1 4096 1A-4k Single_GPU_x16_7B_baseline"
    "B 7B 1 1024 1B-1k Dual_GPU_x8_7B_single_card"
    "B 7B 1 2048 1B-2k Dual_GPU_x8_7B_single_card"
    "B 7B 1 4096 1B-4k Dual_GPU_x8_7B_single_card"
    "C 7B 1 1024 1C-1k Dual_GPU_x16_7B_single_card"
    "C 7B 1 2048 1C-2k Dual_GPU_x16_7B_single_card"
    "C 7B 1 4096 1C-4k Dual_GPU_x16_7B_single_card"

    # Group 2: TP=2 communication tests (7B model)
    "B 7B 2 1024 2B-1k x8_TP_communication"
    "B 7B 2 2048 2B-2k x8_TP_communication"
    "B 7B 2 4096 2B-4k x8_TP_communication"
    "C 7B 2 1024 2C-1k x16_TP_communication"
    "C 7B 2 2048 2C-2k x16_TP_communication"
    "C 7B 2 4096 2C-4k x16_TP_communication"

    # Group 3: 13B model tests
    "A 13B 1 1024 3A-1k VRAM_tight_single_GPU"
    "A 13B 1 2048 3A-2k VRAM_tight_single_GPU"
    "B 13B 2 1024 3B-1k TP2_stable_configuration"
    "B 13B 2 2048 3B-2k TP2_stable_configuration"
    "B 13B 2 4096 3B-4k TP2_stable_configuration"
    "C 13B 2 1024 3C-1k TP2_stable_configuration"
    "C 13B 2 2048 3C-2k TP2_stable_configuration"
    "C 13B 2 4096 3C-4k TP2_stable_configuration"

    # Group 4: 30B model tests (TP=2 only)
    "B 30B 2 1024 4B-1k Large_model_comparison"
    "B 30B 2 2048 4B-2k Large_model_comparison"
    "B 30B 2 4096 4B-4k Large_model_comparison"
    "C 30B 2 1024 4C-1k Large_model_comparison"
    "C 30B 2 2048 4C-2k Large_model_comparison"
    "C 30B 2 4096 4C-4k Large_model_comparison"
)

# 記錄失敗的測試
declare -a FAILED_TEST_IDS=()

# 執行測試
for test_config in "${TEST_MATRIX[@]}"; do
    ((CURRENT_TEST++))

    # 解析測試配置
    read -r CONFIG MODEL_SIZE TP_SIZE INPUT_LEN TEST_ID DESCRIPTION <<< "$test_config"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Test ${CURRENT_TEST}/${TOTAL_TESTS}: ${TEST_ID}${NC}"
    echo -e "${CYAN}Description: ${DESCRIPTION}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # 執行測試
    if "$BENCHMARK_SCRIPT" --config "$CONFIG" --model "$MODEL_SIZE" --tp "$TP_SIZE" --input-len "$INPUT_LEN"; then
        ((PASSED_TESTS++))
        echo -e "${GREEN}✓ Test ${TEST_ID} PASSED${NC}"
    else
        ((FAILED_TESTS++))
        FAILED_TEST_IDS+=("$TEST_ID")
        echo -e "${RED}✗ Test ${TEST_ID} FAILED${NC}"

        # 詢問是否繼續
        echo -e "${YELLOW}Do you want to continue with remaining tests? (y/n)${NC}"
        read -r -n 1 CONTINUE
        echo
        if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
            echo -e "${RED}Test suite aborted by user${NC}"
            break
        fi
    fi

    # 測試間等待，避免資源競爭
    if [[ $CURRENT_TEST -lt $TOTAL_TESTS ]]; then
        echo -e "${BLUE}Waiting 5 seconds before next test...${NC}"
        sleep 5
    fi
done

# 顯示最終結果
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Test Suite Summary                      ║${NC}"
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
    exit 1
else
    echo -e "${GREEN}All tests completed successfully! 🎉${NC}"
    echo ""
    exit 0
fi
