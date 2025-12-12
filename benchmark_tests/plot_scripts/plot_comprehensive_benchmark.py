#!/usr/bin/env python3
"""
vLLM Comprehensive Benchmark Results Visualization

生成包含多個指標的完整基準測試報告
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


def plot_comprehensive_benchmark(results_by_num_prompts, output_file):
    """
    生成包含多個子圖的綜合基準測試報告

    子圖包括:
    1. Output Throughput vs Context Length
    2. TTFT (Time To First Token) vs Context Length
    3. TPOT (Time Per Output Token) vs Context Length
    """
    if not results_by_num_prompts:
        print("錯誤: 沒有數據可以繪制")
        return

    # 配色方案：藍色、紫色、橘色、紅色、綠色
    colors = ['#1f77b4', '#9467bd', '#ff7f0e', '#d62728', '#2ca02c']

    # 創建 1x3 子圖佈局
    fig = plt.figure(figsize=(24, 7))
    gs = gridspec.GridSpec(1, 3, figure=fig, hspace=0.3, wspace=0.25, bottom=0.15)

    # 獲取所有輸入長度用於 X 軸
    all_input_lens = sorted(set([
        x for _, data_points in results_by_num_prompts.items()
        for x, _ in data_points
    ]))

    # ========== 子圖 1: Output Throughput vs Context Length ==========
    ax1 = fig.add_subplot(gs[0, 0])
    for idx, num_prompts in enumerate(sorted(results_by_num_prompts.keys())):
        data_points = results_by_num_prompts[num_prompts]
        input_lens = []
        throughputs = []

        for input_len_k, data in data_points:
            input_lens.append(input_len_k)
            throughput = data.get('output_throughput', 0)
            throughputs.append(throughput)

        color = colors[idx % len(colors)]
        ax1.plot(input_lens, throughputs, marker='o', linewidth=2,
                markersize=8, label=f'{num_prompts} users', color=color)

    ax1.set_xlabel('Context Length (K tokens)', fontsize=9)
    ax1.set_ylabel('Throughput (tokens/sec)', fontsize=9)
    ax1.set_title('Output Throughput vs Context Length', fontsize=11, fontweight='bold')
    ax1.legend(title='Concurrent Users', loc='best', framealpha=0.9, fontsize=7, title_fontsize=8)
    ax1.grid(True, alpha=0.3)
    ax1.set_xticks(all_input_lens)
    ax1.set_xticklabels([f'{x}K' for x in all_input_lens], rotation=45, ha='right')
    ax1.tick_params(axis='x', labelsize=7)
    ax1.tick_params(axis='y', labelsize=7)

    # ========== 子圖 2: TTFT vs Context Length ==========
    ax2 = fig.add_subplot(gs[0, 1])
    for idx, num_prompts in enumerate(sorted(results_by_num_prompts.keys())):
        data_points = results_by_num_prompts[num_prompts]
        input_lens = []
        ttfts = []

        for input_len_k, data in data_points:
            input_lens.append(input_len_k)
            ttft_ms = data.get('mean_ttft_ms', 0)
            ttfts.append(ttft_ms / 1000.0)  # ms 轉 s

        color = colors[idx % len(colors)]
        ax2.plot(input_lens, ttfts, marker='s', linewidth=2,
                markersize=8, label=f'{num_prompts} users', color=color)

    ax2.set_xlabel('Context Length (K tokens)', fontsize=9)
    ax2.set_ylabel('TTFT (s)', fontsize=9)
    ax2.set_title('Time To First Token vs Context Length', fontsize=11, fontweight='bold')
    ax2.legend(title='Concurrent Users', loc='best', framealpha=0.9, fontsize=7, title_fontsize=8)
    ax2.grid(True, alpha=0.3)
    ax2.set_xticks(all_input_lens)
    ax2.set_xticklabels([f'{x}K' for x in all_input_lens], rotation=45, ha='right')
    ax2.tick_params(axis='x', labelsize=7)
    ax2.tick_params(axis='y', labelsize=7)

    # ========== 子圖 3: TPOT vs Context Length ==========
    ax3 = fig.add_subplot(gs[0, 2])
    for idx, num_prompts in enumerate(sorted(results_by_num_prompts.keys())):
        data_points = results_by_num_prompts[num_prompts]
        input_lens = []
        tpots = []

        for input_len_k, data in data_points:
            input_lens.append(input_len_k)
            tpot = data.get('mean_tpot_ms', 0)
            tpots.append(tpot)

        color = colors[idx % len(colors)]
        ax3.plot(input_lens, tpots, marker='^', linewidth=2,
                markersize=8, label=f'{num_prompts} users', color=color)

    ax3.set_xlabel('Context Length (K tokens)', fontsize=9)
    ax3.set_ylabel('TPOT (ms)', fontsize=9)
    ax3.set_title('Time Per Output Token vs Context Length', fontsize=11, fontweight='bold')
    ax3.legend(title='Concurrent Users', loc='best', framealpha=0.9, fontsize=7, title_fontsize=8)
    ax3.grid(True, alpha=0.3)
    ax3.set_xticks(all_input_lens)
    ax3.set_xticklabels([f'{x}K' for x in all_input_lens], rotation=45, ha='right')
    ax3.tick_params(axis='x', labelsize=7)
    ax3.tick_params(axis='y', labelsize=7)

    # 添加總標題
    fig.suptitle('vLLM Benchmark - Comprehensive Performance Analysis',
                 fontsize=13, fontweight='bold', y=0.995)

    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\n✓ 綜合報告已保存: {output_file}")


def main():
    parser = argparse.ArgumentParser(description='vLLM 綜合基準測試結果可視化')
    parser.add_argument('--results-dir', default='bench_results/production',
                       help='結果文件目錄 (默認: bench_results/production)')
    parser.add_argument('--prefix', default='input',
                       help='文件名前綴 (默認: input)')
    parser.add_argument('--output', default='benchmark_comprehensive.png',
                       help='輸出圖表文件名 (默認: benchmark_comprehensive.png)')

    args = parser.parse_args()

    print(f"讀取結果目錄: {args.results_dir}")
    print(f"文件前綴: {args.prefix}")
    print()

    # 加載結果
    results_by_num_prompts = load_input_results(args.results_dir, args.prefix)

    if not results_by_num_prompts:
        print("錯誤: 未找到任何結果文件")
        return

    # 生成綜合報告
    plot_comprehensive_benchmark(results_by_num_prompts, args.output)

    print(f"\n完成! 綜合報告已保存到: {args.output}")


if __name__ == '__main__':
    main()
