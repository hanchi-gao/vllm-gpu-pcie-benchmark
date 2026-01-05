#!/bin/bash
# PCIe Bandwidth Impact Benchmark Script for vLLM
# 測試不同硬體配置、模型大小、TP設定對 vLLM 性能的影響

set -e

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 預設參數
CONFIG=""
MODEL_SIZE=""
TP_SIZE=1
INPUT_LEN=1024
OUTPUT_LEN=128
NUM_PROMPTS_START=${NUM_PROMPTS_START:-1}
NUM_PROMPTS_END=${NUM_PROMPTS_END:-200}
VLLM_SERVER_URL="${VLLM_SERVER_URL:-http://vllm-server:8000}"
RESULTS_DIR="/root/bench_results/pcie"

# 模型映射
declare -A MODEL_MAP
MODEL_MAP["7B"]="meta-llama/Llama-3.1-8B"
MODEL_MAP["14B"]="Qwen/Qwen3-14B"
MODEL_MAP["30B"]="google/gemma-3-27b-it"

# 配置描述映射
declare -A CONFIG_DESC
CONFIG_DESC["A"]="Single_GPU_x16"
CONFIG_DESC["B"]="Dual_GPU_x8"
CONFIG_DESC["C"]="Dual_GPU_x16"

# 顯示使用說明
show_usage() {
    cat << EOF
Usage: $0 --config <A|B|C> --model <7B|14B|30B> [OPTIONS]

Required Parameters:
  --config <A|B|C>        Hardware configuration
                          A: Single GPU x16 (32 GB/s)
                          B: Dual GPU x8 (2×16 GB/s)
                          C: Dual GPU x16 (2×32 GB/s)

  --model <7B|14B|30B>    Model size
                          7B:  meta-llama/Llama-3.1-8B
                          14B: Qwen/Qwen3-14B
                          30B: google/gemma-3-27b-it

Optional Parameters:
  --tp <1|2>              Tensor parallel size (default: 1)
  --input-len <tokens>    Input length in tokens (default: 1024)
  --output-len <tokens>   Output length in tokens (default: 128)
  --help                  Show this help message

Examples:
  # Test ID: 1A-1k (Config A, 7B model, TP=1, 1K input)
  $0 --config A --model 7B --tp 1 --input-len 1024

  # Test ID: 2B-2k (Config B, 7B model, TP=2, 2K input)
  $0 --config B --model 7B --tp 2 --input-len 2048

  # Test ID: 3C-4k (Config C, 14B model, TP=2, 4K input)
  $0 --config C --model 14B --tp 2 --input-len 4096

EOF
}

# 解析參數
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG="$2"
            shift 2
            ;;
        --model)
            MODEL_SIZE="$2"
            shift 2
            ;;
        --tp)
            TP_SIZE="$2"
            shift 2
            ;;
        --input-len)
            INPUT_LEN="$2"
            shift 2
            ;;
        --output-len)
            OUTPUT_LEN="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown parameter: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# 參數驗證
if [[ -z "$CONFIG" ]] || [[ -z "$MODEL_SIZE" ]]; then
    echo -e "${RED}Error: --config and --model are required${NC}\n"
    show_usage
    exit 1
fi

if [[ ! "$CONFIG" =~ ^[ABC]$ ]]; then
    echo -e "${RED}Error: --config must be A, B, or C${NC}"
    exit 1
fi

if [[ ! "$MODEL_SIZE" =~ ^(7B|14B|30B)$ ]]; then
    echo -e "${RED}Error: --model must be 7B, 14B, or 30B${NC}"
    exit 1
fi

if [[ ! "$TP_SIZE" =~ ^[12]$ ]]; then
    echo -e "${RED}Error: --tp must be 1 or 2${NC}"
    exit 1
fi

# 獲取完整模型名稱
MODEL_NAME="${MODEL_MAP[$MODEL_SIZE]}"

# 計算輸入長度標籤 (1024 -> 1k, 2048 -> 2k, etc.)
if [[ $INPUT_LEN -ge 1024 ]]; then
    INPUT_LABEL="$((INPUT_LEN / 1024))k"
else
    INPUT_LABEL="${INPUT_LEN}"
fi

# 生成測試 ID
TEST_ID="${TP_SIZE}${CONFIG}-${INPUT_LABEL}"

# 配置說明
CONFIG_NAME="${CONFIG_DESC[$CONFIG]}"

# 結果檔案名稱
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="${RESULTS_DIR}/${CONFIG}_${MODEL_SIZE}_TP${TP_SIZE}_${INPUT_LABEL}_${TIMESTAMP}.json"

# 確保結果目錄存在
mkdir -p "$RESULTS_DIR"

# 顯示測試配置
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          vLLM PCIe Bandwidth Impact Benchmark              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Test Configuration:${NC}"
echo -e "  Test ID:          ${YELLOW}${TEST_ID}${NC}"
echo -e "  Hardware Config:  ${YELLOW}${CONFIG} (${CONFIG_NAME})${NC}"
echo -e "  Model:            ${YELLOW}${MODEL_NAME} (${MODEL_SIZE})${NC}"
echo -e "  Tensor Parallel:  ${YELLOW}${TP_SIZE}${NC}"
echo -e "  Input Length:     ${YELLOW}${INPUT_LEN} tokens (${INPUT_LABEL})${NC}"
echo -e "  Output Length:    ${YELLOW}${OUTPUT_LEN} tokens${NC}"
echo -e "  vLLM Server:      ${YELLOW}${VLLM_SERVER_URL}${NC}"
echo -e "  Result File:      ${YELLOW}${RESULT_FILE}${NC}"
echo ""

# 檢查 vLLM server 是否運行
echo -e "${BLUE}[1/3] Checking vLLM server status...${NC}"
if ! curl -s "${VLLM_SERVER_URL}/health" > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to vLLM server at ${VLLM_SERVER_URL}${NC}"
    echo -e "${YELLOW}Please ensure vLLM server is running with the correct model:${NC}"
    echo ""
    echo "  vllm serve ${MODEL_NAME} \\"
    echo "    --tensor-parallel-size ${TP_SIZE} \\"
    echo "    --gpu-memory-utilization 0.9 \\"
    echo "    --max-model-len 1280 \\"
    echo "    --enforce-eager"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ vLLM server is running${NC}"
echo ""

# 檢查模型是否匹配
echo -e "${BLUE}[2/3] Verifying model loaded on server...${NC}"
LOADED_MODEL=$(curl -s "${VLLM_SERVER_URL}/v1/models" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [[ "$LOADED_MODEL" != "$MODEL_NAME" ]]; then
    echo -e "${YELLOW}Warning: Server is running model '${LOADED_MODEL}'${NC}"
    echo -e "${YELLOW}Expected model: '${MODEL_NAME}'${NC}"
    echo -e "${YELLOW}Please restart vLLM server with the correct model${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Model verified: ${LOADED_MODEL}${NC}"
fi
echo ""

# 執行測試
echo -e "${BLUE}[3/3] Running benchmark with num_prompts from ${NUM_PROMPTS_START} to ${NUM_PROMPTS_END}...${NC}"
echo -e "${YELLOW}This will take considerable time. Progress will be shown for each test.${NC}"
echo ""

# 測試統計
TOTAL_TESTS=$((NUM_PROMPTS_END - NUM_PROMPTS_START + 1))
COMPLETED=0
FAILED=0

# 循環測試不同的 num_prompts
for NUM_PROMPTS in $(seq $NUM_PROMPTS_START $NUM_PROMPTS_END); do
    COMPLETED=$((COMPLETED + 1))

    echo -e "${CYAN}[${COMPLETED}/${TOTAL_TESTS}] Testing num_prompts: ${NUM_PROMPTS}${NC}"

    # 結果檔案名稱（包含 num_prompts）
    PROMPTS_RESULT_FILE="${RESULTS_DIR}/${CONFIG}_${MODEL_SIZE}_TP${TP_SIZE}_${INPUT_LABEL}_np${NUM_PROMPTS}_${TIMESTAMP}.json"

    # 構建 vllm bench 命令（隱藏詳細輸出，只保留結果）
    vllm bench serve \
        --model "$MODEL_NAME" \
        --backend openai \
        --endpoint /v1/completions \
        --base-url "$VLLM_SERVER_URL" \
        --dataset-name random \
        --random-input-len "$INPUT_LEN" \
        --random-output-len "$OUTPUT_LEN" \
        --num-prompts "$NUM_PROMPTS" \
        --save-result \
        --result-filename "temp_result_${NUM_PROMPTS}.json" > /dev/null 2>&1

    # 檢查測試是否成功
    if [[ $? -ne 0 ]] || [[ ! -f "temp_result_${NUM_PROMPTS}.json" ]]; then
        echo -e "${RED}✗ num_prompts ${NUM_PROMPTS} failed${NC}"
        FAILED=$((FAILED + 1))
        rm -f "temp_result_${NUM_PROMPTS}.json"
        continue
    fi

    # 移動結果文件（保持 vLLM 原始格式）
    mv "temp_result_${NUM_PROMPTS}.json" "${PROMPTS_RESULT_FILE}"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ num_prompts ${NUM_PROMPTS} completed${NC}"
    else
        echo -e "${RED}✗ num_prompts ${NUM_PROMPTS} failed to save${NC}"
        FAILED=$((FAILED + 1))
    fi

    # 刪除臨時文件
    rm -f "temp_result_${NUM_PROMPTS}.json"

done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Benchmark Suite Completed!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Total tests: ${TOTAL_TESTS}${NC}"
echo -e "${GREEN}Completed: $((TOTAL_TESTS - FAILED))${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo ""
echo -e "${GREEN}Results saved to:${NC} ${YELLOW}${RESULTS_DIR}/${NC}"
echo -e "${YELLOW}Pattern: ${CONFIG}_${MODEL_SIZE}_TP${TP_SIZE}_${INPUT_LABEL}_np*_${TIMESTAMP}.json${NC}"
echo ""

exit 0
