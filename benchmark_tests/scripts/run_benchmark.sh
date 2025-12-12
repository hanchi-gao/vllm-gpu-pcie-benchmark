#!/bin/bash
#
# vLLM 基准测试脚本
# 用法: ./run_benchmark.sh [选项]
#

set -e

# 默认配置
SERVER_URL="${VLLM_SERVER_URL:-http://vllm-server:8000}"
MODEL="${MODEL:-openai/gpt-oss-120b}"
NUM_PROMPTS="${NUM_PROMPTS:-20}"
MIN_CONCURRENCY="${MIN_CONCURRENCY:-1}"
MAX_CONCURRENCY="${MAX_CONCURRENCY:-32}"
STEP="${STEP:-1}"
INPUT_LEN="${INPUT_LEN:-256}"
OUTPUT_LEN="${OUTPUT_LEN:-128}"
RESULTS_DIR="${RESULTS_DIR:-/root/bench_results}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -h, --help              显示帮助
  --server URL            服务器地址 (默认: $SERVER_URL)
  --model NAME            模型名称 (默认: $MODEL)
  --num-prompts N         每次测试的请求数 (默认: $NUM_PROMPTS)
  --min-concurrency N     最小并发数 (默认: $MIN_CONCURRENCY)
  --max-concurrency N     最大并发数 (默认: $MAX_CONCURRENCY)
  --step N                并发数递增步长 (默认: $STEP)
  --input-len N           输入长度 (默认: $INPUT_LEN)
  --output-len N          输出长度 (默认: $OUTPUT_LEN)
  --single N              只测试单个并发数

示例:
  $0                                              # 使用默认配置
  $0 --single 8                                   # 只测试 8 并发
  $0 --min-concurrency 1 --max-concurrency 16     # 测试 1-16 并发
  $0 --input-len 128 --output-len 64              # 自定义输入输出长度

环境变量:
  VLLM_SERVER_URL         服务器地址
  MODEL                   模型名称
  NUM_PROMPTS             请求数
  INPUT_LEN               输入长度
  OUTPUT_LEN              输出长度

注意:
  - 确保 input_len + output_len < 模型的最大上下文长度
  - vLLM 会自动检测模型的最大长度
  - 默认配置: input=256, output=128 (总计 384 tokens，适用于大多数模型)
EOF
}

# 解析命令行参数
SINGLE_CONCURRENCY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --server)
            SERVER_URL="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --num-prompts)
            NUM_PROMPTS="$2"
            shift 2
            ;;
        --min-concurrency)
            MIN_CONCURRENCY="$2"
            shift 2
            ;;
        --max-concurrency)
            MAX_CONCURRENCY="$2"
            shift 2
            ;;
        --step)
            STEP="$2"
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
        --single)
            SINGLE_CONCURRENCY="$2"
            shift 2
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 检查服务器连接
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}vLLM 基准测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo "服务器: $SERVER_URL"
echo "模型: $MODEL"
echo "请求数: $NUM_PROMPTS"
echo "输入长度: $INPUT_LEN tokens"
echo "输出长度: $OUTPUT_LEN tokens"
echo

echo -n "检查服务器连接..."
if curl -s -f "$SERVER_URL/health" > /dev/null 2>&1; then
    echo -e " ${GREEN}✓${NC}"
else
    echo -e " ${YELLOW}✗${NC}"
    echo "警告: 无法连接到服务器，请确保服务器正在运行"
    exit 1
fi

echo

# 创建结果目录
mkdir -p "$RESULTS_DIR"

# 运行基准测试
run_bench() {
    local concurrency=$1

    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}测试并发数: $concurrency${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo "当前工作目录: $(pwd)"
    echo

    vllm bench serve \
        --backend openai \
        --base-url "$SERVER_URL" \
        --endpoint /v1/completions \
        --model "$MODEL" \
        --num-prompts "$NUM_PROMPTS" \
        --max-concurrency "$concurrency" \
        --dataset-name random \
        --random-input-len "$INPUT_LEN" \
        --random-output-len "$OUTPUT_LEN" \
        --save-result

    local bench_exit_code=$?
    echo
    echo "基准测试退出代码: $bench_exit_code"
    echo

    # vLLM bench 使用格式: openai-infqps-concurrency{N}-{model}-{timestamp}.json
    # 查找最新生成的结果文件
    local result_pattern="openai-*-concurrency${concurrency}-*.json"
    local latest_file=$(ls -t $result_pattern 2>/dev/null | head -1)

    if [ -n "$latest_file" ] && [ -f "$latest_file" ]; then
        # 使用更简洁的文件名
        local result_file="$RESULTS_DIR/results_c${concurrency}_$(date +%Y%m%d_%H%M%S).json"
        mv "$latest_file" "$result_file"
        echo -e "${GREEN}✓ 结果已保存: $result_file${NC}"
    else
        echo -e "${YELLOW}⚠️  未找到结果文件${NC}"
        echo "查找模式: $result_pattern"
        echo "基准测试退出代码: $bench_exit_code"
    fi

    echo
}

# 如果指定了单个并发数
if [ -n "$SINGLE_CONCURRENCY" ]; then
    echo "测试单个并发数: $SINGLE_CONCURRENCY"
    echo
    run_bench "$SINGLE_CONCURRENCY"
else
    # 测试一系列并发数
    if [ "$MIN_CONCURRENCY" -eq "$MAX_CONCURRENCY" ]; then
        echo "测试并发数: $MIN_CONCURRENCY"
    else
        echo "测试并发数范围: $MIN_CONCURRENCY - $MAX_CONCURRENCY (步长: $STEP)"
    fi
    echo

    for concurrency in $(seq "$MIN_CONCURRENCY" "$STEP" "$MAX_CONCURRENCY"); do
        run_bench "$concurrency"

        # 短暂休息，避免服务器过载
        if [ "$concurrency" -lt "$MAX_CONCURRENCY" ]; then
            echo "等待 5 秒..."
            sleep 5
        fi
    done
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}所有测试完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo "结果保存在: $RESULTS_DIR"
echo
echo "查看结果:"
echo "  ls -lh $RESULTS_DIR"
echo "  cat $RESULTS_DIR/results_c1_*.json  # 查看并发数为 1 的结果"
