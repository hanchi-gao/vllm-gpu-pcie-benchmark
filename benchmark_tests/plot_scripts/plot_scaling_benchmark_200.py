#!/usr/bin/env python3
"""
vLLM Scaling Benchmark Results Visualization

專門用於 run_scaling_bench.sh 的結果可視化
固定 input=1K, output=128，測試 num_prompts 1~1000 的擴展性
"""

import json
import glob
import argparse
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import matplotlib
from matplotlib.ticker import MaxNLocator
matplotlib.use('Agg')


def load_scaling_results(results_dir, prefix="scale"):
    """
    加載 scaling benchmark 結果

    Args:
        results_dir: 結果文件目錄
        prefix: 文件名前綴 (默認: scale)

    Returns:
        list: [(num_prompts, data), ...] 按 num_prompts 排序
    """
    results = []

    pattern = f"{results_dir}/{prefix}_n*.json"
    files = glob.glob(pattern)

    if not files:
        print(f"警告: 未找到匹配的結果文件")
        print(f"嘗試的路徑: {pattern}")
        return results

    print(f"找到 {len(files)} 個結果文件\n")

    for file_path in files:
        filename = Path(file_path).name
        # 從文件名提取信息: scale_n100_20251112_120000.json
        # -> num_prompts=100
        parts = filename.split('_')
        if len(parts) < 3:
            continue

        num_prompts_str = parts[1]  # 例如 "n100"

        if not num_prompts_str.startswith('n'):
            continue

        try:
            num_prompts = int(num_prompts_str[1:])
        except ValueError:
            continue

        with open(file_path, 'r') as f:
            data = json.load(f)

        results.append((num_prompts, data))
        print(f"  加載: Num Prompts={num_prompts}")

    # 按 num_prompts 排序
    results.sort(key=lambda x: x[0])

    return results


def plot_scaling_benchmark(results, output_file):
    """
    生成擴展性測試圖表

    包含 3 個子圖:
    1. Total Token Throughput vs Num Prompts
    2. Output Throughput per Request vs Num Prompts
    3. Mean TTFT vs Num Prompts

    X 軸: num_prompts (1~1000)
    """
    if not results:
        print("錯誤: 沒有數據可以繪制")
        return

    # 創建 1x3 子圖佈局
    fig = plt.figure(figsize=(24, 7))
    gs = gridspec.GridSpec(1, 3, figure=fig, hspace=0.3, wspace=0.25)

    # 提取數據 (僅包含 1-200 範圍)
    num_prompts_list = []
    total_throughputs = []
    output_per_request = []
    ttfts = []

    for num_prompts, data in results:
        # 只繪製 1-200 範圍的數據
        if num_prompts < 1 or num_prompts > 200:
            continue

        num_prompts_list.append(num_prompts)

        # Total token throughput
        total_throughput = data.get('total_token_throughput', 0)
        total_throughputs.append(total_throughput)

        # Output throughput per request
        output_throughput = data.get('output_throughput', 0)
        output_per_request.append(output_throughput / num_prompts if num_prompts > 0 else 0)

        # Mean TTFT
        mean_ttft = data.get('mean_ttft_ms', 0)
        ttfts.append(mean_ttft)

    # ========== 子圖 1: Total Token Throughput ==========
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.plot(num_prompts_list, total_throughputs, marker='o', linewidth=2,
            markersize=6, color='#1f77b4', label='Data Points', alpha=0.6)

    # 添加多項式擬合曲線
    if len(num_prompts_list) >= 3:
        coeffs1 = np.polyfit(num_prompts_list, total_throughputs, 2)
        poly1 = np.poly1d(coeffs1)
        x_smooth = np.linspace(min(num_prompts_list), max(num_prompts_list), 300)
        y_smooth = poly1(x_smooth)
        ax1.plot(x_smooth, y_smooth, '--', linewidth=2.5, color='#d62728',
                label='Polynomial Fit (degree 2)', alpha=0.8)
        ax1.legend(loc='best', fontsize=9)

    ax1.set_xlabel('Number of Prompts', fontsize=11)
    ax1.set_ylabel('Total Token Throughput (tokens/sec)', fontsize=11)
    ax1.set_title('Total Token Throughput vs Request Count\n(Input=1K, Output=128)',
                  fontsize=13, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    # 限制 X 軸範圍到 0-200
    ax1.set_xlim(0, 200)
    # 設定 X 軸刻度 (每 25 一格)
    ax1.set_xticks([0, 25, 50, 75, 100, 125, 150, 175, 200])
    ax1.set_xticklabels(['0', '25', '50', '75', '100', '125', '150', '175', '200'], rotation=0)
    ax1.tick_params(axis='x', labelsize=9)
    # 設定 Y 軸使用精確刻度
    ax1.yaxis.set_major_locator(MaxNLocator(nbins=8, integer=False))

    # ========== 子圖 2: Output Throughput per Request ==========
    ax2 = fig.add_subplot(gs[0, 1])
    ax2.plot(num_prompts_list, output_per_request, marker='s', linewidth=2,
            markersize=6, color='#ff7f0e', label='Data Points', alpha=0.6)

    # 添加多項式擬合曲線
    if len(num_prompts_list) >= 3:
        coeffs2 = np.polyfit(num_prompts_list, output_per_request, 2)
        poly2 = np.poly1d(coeffs2)
        x_smooth = np.linspace(min(num_prompts_list), max(num_prompts_list), 300)
        y_smooth = poly2(x_smooth)
        ax2.plot(x_smooth, y_smooth, '--', linewidth=2.5, color='#d62728',
                label='Polynomial Fit (degree 2)', alpha=0.8)
        ax2.legend(loc='best', fontsize=9)

    ax2.set_xlabel('Number of Prompts', fontsize=11)
    ax2.set_ylabel('Output Throughput per Request (tokens/sec/request)', fontsize=11)
    ax2.set_title('Output Throughput per Request vs Request Count\n(Input=1K, Output=128)',
                  fontsize=13, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    # 限制 X 軸範圍到 0-200
    ax2.set_xlim(0, 200)
    # 設定 X 軸刻度 (每 25 一格)
    ax2.set_xticks([0, 25, 50, 75, 100, 125, 150, 175, 200])
    ax2.set_xticklabels(['0', '25', '50', '75', '100', '125', '150', '175', '200'], rotation=0)
    ax2.tick_params(axis='x', labelsize=9)
    # 設定 Y 軸使用精確刻度
    ax2.yaxis.set_major_locator(MaxNLocator(nbins=8, integer=False))

    # ========== 子圖 3: Mean TTFT ==========
    ax3 = fig.add_subplot(gs[0, 2])
    ax3.plot(num_prompts_list, ttfts, marker='^', linewidth=2,
            markersize=6, color='#2ca02c', label='Data Points', alpha=0.6)

    # 添加多項式擬合曲線
    if len(num_prompts_list) >= 3:
        coeffs3 = np.polyfit(num_prompts_list, ttfts, 2)
        poly3 = np.poly1d(coeffs3)
        x_smooth = np.linspace(min(num_prompts_list), max(num_prompts_list), 300)
        y_smooth = poly3(x_smooth)
        ax3.plot(x_smooth, y_smooth, '--', linewidth=2.5, color='#d62728',
                label='Polynomial Fit (degree 2)', alpha=0.8)
        ax3.legend(loc='best', fontsize=9)

    ax3.set_xlabel('Number of Prompts', fontsize=11)
    ax3.set_ylabel('Mean TTFT (ms)', fontsize=11)
    ax3.set_title('Time To First Token vs Request Count\n(Input=1K, Output=128)',
                  fontsize=13, fontweight='bold')
    ax3.grid(True, alpha=0.3)
    # 限制 X 軸範圍到 0-200
    ax3.set_xlim(0, 200)
    # 設定 X 軸刻度 (每 25 一格)
    ax3.set_xticks([0, 25, 50, 75, 100, 125, 150, 175, 200])
    ax3.set_xticklabels(['0', '25', '50', '75', '100', '125', '150', '175', '200'], rotation=0)
    ax3.tick_params(axis='x', labelsize=9)
    # 設定 Y 軸範圍，根據數據範圍自動調整
    if ttfts:
        y_min = min(ttfts)
        y_max = max(ttfts)
        y_margin = (y_max - y_min) * 0.1  # 10% margin
        ax3.set_ylim(y_min - y_margin, y_max + y_margin)
    # 設定 Y 軸使用精確刻度
    ax3.yaxis.set_major_locator(MaxNLocator(nbins=8, integer=False))

    # 添加總標題
    fig.suptitle('vLLM Scaling Benchmark - Performance vs Request Count (1~200)',
                 fontsize=16, fontweight='bold', y=0.995)

    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"\n✓ 擴展性報告已保存: {output_file}")


def print_summary(results):
    """打印測試結果摘要"""
    if not results:
        print("沒有結果數據")
        return

    print("\n" + "="*90)
    print("擴展性測試結果摘要 (Input=1K, Output=128)")
    print("="*90)
    print(f"{'Num Prompts':<15} {'總吞吐量':<20} {'每請求吞吐量':<20} {'TTFT (ms)':<15} {'TPOT (ms)':<15}")
    print("-"*90)

    for num_prompts, data in results:
        total_throughput = f"{data.get('total_token_throughput', 0):.2f}"
        output_throughput = data.get('output_throughput', 0)
        per_request = f"{output_throughput / num_prompts if num_prompts > 0 else 0:.2f}"
        mean_ttft = f"{data.get('mean_ttft_ms', 0):.2f}"
        mean_tpot = f"{data.get('mean_tpot_ms', 0):.2f}"

        print(f"{num_prompts:<15} {total_throughput:<20} {per_request:<20} {mean_ttft:<15} {mean_tpot:<15}")

    print("="*90 + "\n")


def main():
    parser = argparse.ArgumentParser(description='vLLM 擴展性基準測試結果可視化')
    parser.add_argument('--results-dir', default='bench_results/scaling',
                       help='結果文件目錄 (默認: bench_results/scaling)')
    parser.add_argument('--prefix', default='scale',
                       help='文件名前綴 (默認: scale)')
    parser.add_argument('--output', default='scaling_benchmark.png',
                       help='輸出圖表文件名 (默認: scaling_benchmark.png)')

    args = parser.parse_args()

    print(f"讀取結果目錄: {args.results_dir}")
    print(f"文件前綴: {args.prefix}")
    print()

    # 加載結果
    results = load_scaling_results(args.results_dir, args.prefix)

    if not results:
        print("錯誤: 未找到任何結果文件")
        print(f"請確保 {args.results_dir} 目錄下有 {args.prefix}_n*.json 格式的文件")
        return

    # 打印摘要
    print_summary(results)

    # 生成圖表
    plot_scaling_benchmark(results, args.output)

    print(f"\n完成! 擴展性報告已保存到: {args.output}")


if __name__ == '__main__':
    main()
