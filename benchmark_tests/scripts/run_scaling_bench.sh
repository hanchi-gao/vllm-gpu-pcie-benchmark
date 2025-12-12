#!/bin/bash

#######################################
# vLLM Scaling Benchmark Script
#
# 固定配置:
#   - input-len: 1024 (1K)
#   - output-len: 128
#   - num-prompts: 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000
#
# 目的: 測試系統擴展性 (scaling)
#######################################

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 固定配置
SERVER_URL="${VLLM_SERVER_URL:-http://vllm-server:8000}"
MODEL="${MODEL:-openai/gpt-oss-120b}"
INPUT_LEN=1024
INPUT_LABEL="1K"
OUTPUT_LEN=128
RESULTS_BASE_DIR="${RESULTS_DIR:-/root/bench_results/scaling}"

# Num Prompts 測試點 (1 到 1000)
NUM_PROMPTS_LEVELS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 250 300 350 400 450 500 550 600 650 700 750 800 850 900 950 1000
)

echo -e "${GREEN}========================================"
echo "vLLM Scaling Benchmark"
echo -e "========================================${NC}"
echo
echo "服務器: $SERVER_URL"
echo "模型: $MODEL"
echo "輸入長度: $INPUT_LABEL ($INPUT_LEN tokens)"
echo "輸出長度: $OUTPUT_LEN tokens"
echo "Num Prompts 測試點: ${NUM_PROMPTS_LEVELS[*]}"
echo "結果目錄: $RESULTS_BASE_DIR"
echo

# 檢查服務器連接
echo "檢查服務器連接..."
if ! curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}錯誤: 無法連接到 vLLM 服務器 $SERVER_URL${NC}"
    echo "請確保服務器正在運行"
    exit 1
fi
echo -e "${GREEN}✓ 服務器連接成功${NC}"
echo

# 創建結果目錄
mkdir -p "$RESULTS_BASE_DIR"

# 運行基準測試函數
run_bench() {
    local num_prompts=$1
    local test_num=$2
    local total_tests=$3

    echo -e "${YELLOW}========================================"
    echo "測試 [$test_num/$total_tests]"
    echo "Num Prompts: $num_prompts"
    echo -e "========================================${NC}"

    vllm bench serve \
        --backend openai \
        --base-url "$SERVER_URL" \
        --endpoint /v1/completions \
        --model "$MODEL" \
        --num-prompts "$num_prompts" \
        --dataset-name random \
        --random-input-len "$INPUT_LEN" \
        --random-output-len "$OUTPUT_LEN" \
        --ignore-eos \
        --save-result

    local bench_exit_code=$?
    echo
    echo "基準測試退出代碼: $bench_exit_code"
    echo

    # 查找最新生成的結果文件
    local result_pattern="openai-*.json"
    local latest_file=$(ls -t $result_pattern 2>/dev/null | head -1)

    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        # 使用格式: scale_n{num_prompts}_{時間戳}.json
        # 例如: scale_n100_20251112_120000.json
        local result_file="$RESULTS_BASE_DIR/scale_n${num_prompts}_$(date +%Y%m%d_%H%M%S).json"
        mv "$latest_file" "$result_file"
        echo -e "${GREEN}✓ 結果已保存: $result_file${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到結果文件${NC}"
        echo "查找模式: $result_pattern"
        echo "基準測試退出代碼: $bench_exit_code"
    fi

    echo
}

# 運行所有測試
total_tests=${#NUM_PROMPTS_LEVELS[@]}
test_num=0

echo "開始運行擴展性測試，總共 $total_tests 個測試點"
echo "測試配置: Input=$INPUT_LABEL, Output=$OUTPUT_LEN tokens"
echo

for num_prompts in "${NUM_PROMPTS_LEVELS[@]}"; do
    ((test_num++))
    run_bench "$num_prompts" "$test_num" "$total_tests"
done

# 完成
echo -e "${GREEN}========================================"
echo "所有測試完成！"
echo -e "========================================${NC}"
echo
echo "結果保存在: $RESULTS_BASE_DIR/"
echo "總共生成了 $total_tests 個結果文件"
echo
echo "下一步:"
echo "  1. 查看結果文件:"
echo "     ls -lh $RESULTS_BASE_DIR/scale_*.json"
echo
echo "  2. 生成擴展性圖表 (在主機上運行):"
echo "     ./host_scripts/run_scaling_plot.sh"
echo
