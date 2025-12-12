#!/bin/bash

#######################################
# vLLM Production Benchmark Script
#
# 固定配置:
#   - num-prompts: 1000
#   - output-len: 500
#   - input-len: [1024, 10K, 32K, 64K, 96K, 128K]
#   - concurrency: [1, 2, 5, 10, 20]
#######################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 固定配置
SERVER_URL="${VLLM_SERVER_URL:-http://vllm-server:8000}"
MODEL="${MODEL:-openai/gpt-oss-120b}"
NUM_PROMPTS_LEVELS=(1 2 5 10 20)
OUTPUT_LEN=500
RESULTS_BASE_DIR="${RESULTS_DIR:-/root/bench_results/production}"

# Input length 配置 (input_len:label)
INPUT_CONFIGS=(
    "1024:1K"
    "2048:2K"
    "4096:4K"
    "8192:8K"
    "10240:10K"
    "32768:32K"
    "65536:64K"
    "98304:96K"
    # "131072:128K"
)

echo -e "${GREEN}========================================"
echo "vLLM Production Benchmark"
echo -e "========================================${NC}"
echo
echo "服务器: $SERVER_URL"
echo "模型: $MODEL"
echo "Num Prompts 级别: ${NUM_PROMPTS_LEVELS[*]}"
echo "输出长度: $OUTPUT_LEN tokens"
echo "输入长度配置: ${#INPUT_CONFIGS[@]} 种"
for cfg in "${INPUT_CONFIGS[@]}"; do
    IFS=':' read -r input_len label <<< "$cfg"
    echo "  - $label ($input_len tokens)"
done
echo "结果基础目录: $RESULTS_BASE_DIR"
echo

# 检查服务器连接
echo "检查服务器连接..."
if ! curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}错误: 无法连接到 vLLM 服务器 $SERVER_URL${NC}"
    echo "请确保服务器正在运行"
    exit 1
fi
echo -e "${GREEN}✓ 服务器连接成功${NC}"
echo

# 运行基准测试函数
run_bench() {
    local input_len=$1
    local input_label=$2
    local num_prompts=$3
    local test_num=$4
    local total_tests=$5

    echo -e "${YELLOW}========================================"
    echo "测试 [$test_num/$total_tests]"
    echo "Input: $input_label | Num Prompts: $num_prompts"
    echo -e "========================================${NC}"

    # 直接使用 RESULTS_BASE_DIR (不再創建 prompts_* 子目錄)
    local results_dir="$RESULTS_BASE_DIR"
    mkdir -p "$results_dir"

    vllm bench serve \
        --backend openai \
        --base-url "$SERVER_URL" \
        --endpoint /v1/completions \
        --model "$MODEL" \
        --num-prompts "$num_prompts" \
        --dataset-name random \
        --random-input-len "$input_len" \
        --random-output-len "$OUTPUT_LEN" \
        --ignore-eos \
        --save-result

    local bench_exit_code=$?
    echo
    echo "基准测试退出代码: $bench_exit_code"
    echo

    # vLLM bench 使用格式: openai-infqps-{backend}-{model}-{timestamp}.json (没有 concurrency)
    # 查找最新生成的结果文件
    local result_pattern="openai-*.json"
    local latest_file=$(ls -t $result_pattern 2>/dev/null | head -1)

    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        # 使用格式: input_{label}_n{num_prompts}_{时间戳}.json
        # 例如: input_32K_n10_20251107_080000.json
        local result_file="$results_dir/input_${input_label}_n${num_prompts}_$(date +%Y%m%d_%H%M%S).json"
        mv "$latest_file" "$result_file"
        echo -e "${GREEN}✓ 结果已保存: $result_file${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到结果文件${NC}"
        echo "查找模式: $result_pattern"
        echo "基准测试退出代码: $bench_exit_code"
    fi

    echo
}

# 运行所有测试
total_input_configs=${#INPUT_CONFIGS[@]}
total_num_prompts_levels=${#NUM_PROMPTS_LEVELS[@]}
total_tests=$((total_input_configs * total_num_prompts_levels))
test_num=0

echo "开始运行测试，总共 $total_tests 个测试点"
echo "($total_input_configs 种输入长度 × $total_num_prompts_levels 种 num_prompts 级别)"
echo

for cfg in "${INPUT_CONFIGS[@]}"; do
    IFS=':' read -r input_len input_label <<< "$cfg"

    echo -e "${GREEN}--- Input Length: $input_label ($input_len tokens) ---${NC}"
    echo

    for num_prompts in "${NUM_PROMPTS_LEVELS[@]}"; do
        ((test_num++))
        run_bench "$input_len" "$input_label" "$num_prompts" "$test_num" "$total_tests"
    done

    echo
done

# 完成
echo -e "${GREEN}========================================"
echo "所有测试完成！"
echo -e "========================================${NC}"
echo
echo "結果保存在: $RESULTS_BASE_DIR/"
echo "總共生成了 $total_tests 個結果文件"
echo
echo "下一步:"
echo "  1. 查看結果文件:"
echo "     ls -lh $RESULTS_BASE_DIR/input_*.json"
echo
echo "  2. 生成性能圖表 (在主機上運行):"
echo "     ./host_scripts/run_plot.sh"
echo "     ./host_scripts/run_comprehensive_plot.sh"
echo "     ./host_scripts/run_normalized_plot.sh"
echo
