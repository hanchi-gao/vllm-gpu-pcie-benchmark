#!/usr/bin/env python3
"""
vLLM Normalized Benchmark Results Visualization

生成按 num_prompts 標準化的性能指標圖表
"""

import json
import glob
import argparse
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib
matplotlib.use('Agg')

def parse_input_label(label):
    """將輸入長度標籤轉換為數值（以 K tokens 為單位）"""
    if label.endswith('K'):
        return int(label[:-1])
    return int(label) // 1024


def load_input_results(results_dir, prefix="input"):
    """
    加載基準測試結果（按 num_prompts 組織）

    Returns:
        dict: {num_prompts: [(input_len_k, data), ...]}
    """
    results_by_num_prompts = {}

    # 查找匹配的結果文件
    pattern = f"{results_dir}/{prefix}_*_n*_*.json"
    files = glob.glob(pattern)

    if not files:
        print(f"警告: 未找到匹配的結果文件")
        print(f"嘗試的路徑: {results_dir}/{prefix}_*_n*_*.json")
        return results_by_num_prompts

    print(f"找到 {len(files)} 個結果文件\n")

    for file_path in files:
        filename = Path(file_path).name
        parts = filename.split('_')
        if len(parts) < 4:
            continue

        input_label = parts[1]
        num_prompts_str = parts[2]

        if not num_prompts_str.startswith('n'):
            continue

        try:
            num_prompts = int(num_prompts_str[1:])
            input_len_k = parse_input_label(input_label)
        except ValueError:
            continue

        with open(file_path, 'r') as f:
            data = json.load(f)

        if num_prompts not in results_by_num_prompts:
            results_by_num_prompts[num_prompts] = []

        results_by_num_prompts[num_prompts].append((input_len_k, data))
        print(f"  加載: Input={input_label}, Num Prompts={num_prompts}")

    # 對每個 num_prompts 的結果按 input_len 排序
    for num_prompts in results_by_num_prompts:
        results_by_num_prompts[num_prompts].sort(key=lambda x: x[0])

    return results_by_num_prompts


def plot_normalized_benchmark(results_by_num_prompts, output_file):
    """
    生成性能指標圖表

    子圖包括:
    1. Total Token Throughput vs Num Prompts (不除)
    2. Output Token Throughput / num_prompts vs Num Prompts (每請求)
    3. Mean TTFT vs Num Prompts

    X 軸: num_prompts (請求數量)
    每條線: 不同的 context length
    """
    if not results_by_num_prompts:
        print("錯誤: 沒有數據可以繪制")
        return

    # 配色方案：藍色、紫色、橘色、紅色、綠色
    colors = ['#1f77b4', '#9467bd', '#ff7f0e', '#d62728', '#2ca02c']

    # 創建 1x3 子圖佈局
    fig = plt.figure(figsize=(24, 7))
    gs = gridspec.GridSpec(1, 3, figure=fig, hspace=0.3, wspace=0.25)

    # 重新組織數據：{input_len_k: [(num_prompts, data), ...]}
    results_by_input_len = {}
    for num_prompts, data_points in results_by_num_prompts.items():
        for input_len_k, data in data_points:
            if input_len_k not in results_by_input_len:
                results_by_input_len[input_len_k] = []
            results_by_input_len[input_len_k].append((num_prompts, data))

    # 對每個 input_len 的數據按 num_prompts 排序
    for input_len_k in results_by_input_len:
        results_by_input_len[input_len_k].sort(key=lambda x: x[0])

    # 獲取所有 num_prompts 值用於 X 軸
    all_num_prompts = sorted(results_by_num_prompts.keys())

    # ========== 子圖 1: Total Token Throughput (不除以 num_prompts) ==========
    ax1 = fig.add_subplot(gs[0, 0])
    for idx, input_len_k in enumerate(sorted(results_by_input_len.keys())):
        data_points = results_by_input_len[input_len_k]
        num_prompts_list = []
        total_throughputs = []

        for num_prompts, data in data_points:
            num_prompts_list.append(num_prompts)
            total_throughput = data.get('total_token_throughput', 0)
            total_throughputs.append(total_throughput)

        color = colors[idx % len(colors)]
        ax1.plot(num_prompts_list, total_throughputs, marker='o', linewidth=2,
                markersize=8, label=f'{input_len_k}K tokens', color=color)

    ax1.set_xlabel('Number of Prompts', fontsize=11)
    ax1.set_ylabel('Total Token Throughput (tokens/sec)', fontsize=11)
    ax1.set_title('Total Token Throughput vs Number of Requests', fontsize=13, fontweight='bold')
    ax1.legend(title='Context Length', loc='best', framealpha=0.9, fontsize=9)
    ax1.grid(True, alpha=0.3)
    ax1.set_xticks(all_num_prompts)
    ax1.set_xticklabels([str(x) for x in all_num_prompts], rotation=0)
    ax1.tick_params(axis='x', labelsize=9)

    # ========== 子圖 2: Output Token Throughput / num_prompts ==========
    ax2 = fig.add_subplot(gs[0, 1])
    for idx, input_len_k in enumerate(sorted(results_by_input_len.keys())):
        data_points = results_by_input_len[input_len_k]
        num_prompts_list = []
        normalized_output_throughputs = []

        for num_prompts, data in data_points:
            num_prompts_list.append(num_prompts)
            output_throughput = data.get('output_throughput', 0)
            normalized_output_throughputs.append(output_throughput / num_prompts if num_prompts > 0 else 0)

        color = colors[idx % len(colors)]
        ax2.plot(num_prompts_list, normalized_output_throughputs, marker='s', linewidth=2,
                markersize=8, label=f'{input_len_k}K tokens', color=color)

    ax2.set_xlabel('Number of Prompts', fontsize=11)
    ax2.set_ylabel('Output Throughput per Request (tokens/sec/request)', fontsize=11)
    ax2.set_title('Output Throughput per Request vs Number of Requests', fontsize=13, fontweight='bold')
    ax2.legend(title='Context Length', loc='best', framealpha=0.9, fontsize=9)
    ax2.grid(True, alpha=0.3)
    ax2.set_xticks(all_num_prompts)
    ax2.set_xticklabels([str(x) for x in all_num_prompts], rotation=0)
    ax2.tick_params(axis='x', labelsize=9)

    # ========== 子圖 3: Mean TTFT ==========
    ax3 = fig.add_subplot(gs[0, 2])
    for idx, input_len_k in enumerate(sorted(results_by_input_len.keys())):
        data_points = results_by_input_len[input_len_k]
        num_prompts_list = []
        ttfts = []

        for num_prompts, data in data_points:
            num_prompts_list.append(num_prompts)
            mean_ttft = data.get('mean_ttft_ms', 0)
            ttfts.append(mean_ttft)

        color = colors[idx % len(colors)]
        ax3.plot(num_prompts_list, ttfts, marker='^', linewidth=2,
                markersize=8, label=f'{input_len_k}K tokens', color=color)

    ax3.set_xlabel('Number of Prompts', fontsize=11)
    ax3.set_ylabel('Mean TTFT (ms)', fontsize=11)
    ax3.set_title('Time To First Token vs Number of Requests', fontsize=13, fontweight='bold')
    ax3.legend(title='Context Length', loc='best', framealpha=0.9, fontsize=9)
    ax3.grid(True, alpha=0.3)
    ax3.set_xticks(all_num_prompts)
    ax3.set_xticklabels([str(x) for x in all_num_prompts], rotation=0)
    ax3.tick_params(axis='x', labelsize=9)

    # 添加總標題
    fig.suptitle('vLLM Benchmark - Performance Metrics vs Request Count',
                 fontsize=16, fontweight='bold', y=0.995)

    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\n✓ 標準化報告已保存: {output_file}")


def main():
    parser = argparse.ArgumentParser(description='vLLM 標準化基準測試結果可視化')
    parser.add_argument('--results-dir', default='bench_results/production',
                       help='結果文件目錄 (默認: bench_results/production)')
    parser.add_argument('--prefix', default='input',
                       help='文件名前綴 (默認: input)')
    parser.add_argument('--output', default='benchmark_normalized.png',
                       help='輸出圖表文件名 (默認: benchmark_normalized.png)')

    args = parser.parse_args()

    print(f"讀取結果目錄: {args.results_dir}")
    print(f"文件前綴: {args.prefix}")
    print()

    # 加載結果
    results_by_num_prompts = load_input_results(args.results_dir, args.prefix)

    if not results_by_num_prompts:
        print("錯誤: 未找到任何結果文件")
        return

    # 生成標準化報告
    plot_normalized_benchmark(results_by_num_prompts, args.output)

    print(f"\n完成! 標準化報告已保存到: {args.output}")


if __name__ == '__main__':
    main()
