#!/usr/bin/env python3
"""
Plot PCIe benchmark results similar to the reference image.
Creates 4 subplots:
1. System Output Throughput vs Concurrency
2. Output Speed per Query vs Concurrency
3. Time to First Token vs Concurrency
4. End-to-End Latency vs Concurrency
"""

import json
import glob
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path
from collections import defaultdict

# Set style
plt.style.use('seaborn-v0_8-darkgrid')

def parse_filename(filename):
    """Parse filename to extract configuration details."""
    parts = Path(filename).stem.split('_')
    config = parts[0]  # C
    model = parts[1]   # 7B, 14B, 30B
    tp = parts[2]      # TP1, TP2
    input_len = parts[3]  # 1k
    num_prompts = int(parts[4].replace('np', ''))

    return {
        'config': config,
        'model': model,
        'tp': tp,
        'input_len': input_len,
        'num_prompts': num_prompts
    }

def load_results(results_dir='bench_results/pcie'):
    """Load all JSON results and organize by configuration."""
    data = defaultdict(list)

    json_files = sorted(glob.glob(f'{results_dir}/*.json'))

    for filepath in json_files:
        with open(filepath, 'r') as f:
            result = json.load(f)

        info = parse_filename(filepath)
        key = f"{info['config']}_{info['model']}_{info['tp']}_{info['input_len']}"

        data[key].append({
            'concurrency': info['num_prompts'],
            'output_throughput': result.get('output_throughput', 0),
            'output_speed_per_query': result.get('output_throughput', 0) / info['num_prompts'] if info['num_prompts'] > 0 else 0,
            'mean_ttft_ms': result.get('mean_ttft_ms', 0),
            'mean_e2e_latency_ms': result.get('mean_ttft_ms', 0) + result.get('mean_tpot_ms', 0) * result.get('total_output_tokens', 128) / info['num_prompts'] if info['num_prompts'] > 0 else 0,
            'request_throughput': result.get('request_throughput', 0),
            'mean_tpot_ms': result.get('mean_tpot_ms', 0),
            'total_output_tokens': result.get('total_output_tokens', 0),
        })

    # Sort each configuration by concurrency
    for key in data:
        data[key] = sorted(data[key], key=lambda x: x['concurrency'])

    return data

def get_model_label(config_key):
    """Generate a readable label for the configuration."""
    parts = config_key.split('_')
    config = parts[0]
    model = parts[1]
    tp = parts[2]

    # Map model sizes to actual model names
    model_names = {
        '7B': 'Llama-3.1-8B',
        '14B': 'Qwen3-8B',
        '30B': 'gemma-3-4b-it'
    }

    tp_size = tp.replace('TP', 'TP=')
    return f"{model_names.get(model, model)}"

def plot_results(data, output_file='pcie_benchmark_results.png'):
    """Create 4-panel plot similar to the reference image."""

    fig, axes = plt.subplots(2, 2, figsize=(16, 10))
    fig.suptitle('vLLM PCIe Bandwidth Impact Analysis', fontsize=16, fontweight='bold')

    # Color palette
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']

    for idx, (config_key, results) in enumerate(data.items()):
        if not results:
            continue

        concurrency = [r['concurrency'] for r in results]
        color = colors[idx % len(colors)]
        label = get_model_label(config_key)

        # Plot 1: System Output Throughput
        output_throughput = [r['output_throughput'] for r in results]
        axes[0, 0].plot(concurrency, output_throughput, marker='o',
                       color=color, label=label, linewidth=2, markersize=4)

        # Plot 2: Output Speed per Query
        output_speed_per_query = [r['output_speed_per_query'] for r in results]
        axes[0, 1].plot(concurrency, output_speed_per_query, marker='o',
                       color=color, label=label, linewidth=2, markersize=4)

        # Plot 3: Time to First Token
        ttft = [r['mean_ttft_ms'] for r in results]
        axes[1, 0].plot(concurrency, ttft, marker='o',
                       color=color, label=label, linewidth=2, markersize=4)

        # Plot 4: End-to-End Latency
        # Calculate approximate E2E latency
        e2e_latency = []
        for r in results:
            # E2E latency ≈ TTFT + (output_tokens / concurrency) * TPOT
            if r['concurrency'] > 0:
                latency = r['mean_ttft_ms'] + (r['total_output_tokens'] / r['concurrency']) * r['mean_tpot_ms']
            else:
                latency = 0
            e2e_latency.append(latency)

        axes[1, 1].plot(concurrency, e2e_latency, marker='o',
                       color=color, label=label, linewidth=2, markersize=4)

    # Configure Plot 1: System Output Throughput
    axes[0, 0].set_xlabel('Concurrency', fontsize=11)
    axes[0, 0].set_ylabel('Output Throughput (Tokens/s)', fontsize=11)
    axes[0, 0].set_title('System Output Throughput', fontsize=12, fontweight='bold')
    axes[0, 0].legend(loc='best', fontsize=9)
    axes[0, 0].grid(True, alpha=0.3)

    # Configure Plot 2: Output Speed per Query
    axes[0, 1].set_xlabel('Concurrency', fontsize=11)
    axes[0, 1].set_ylabel('Output Speed per Query (Tokens/s)', fontsize=11)
    axes[0, 1].set_title('Output Speed per Query', fontsize=12, fontweight='bold')
    axes[0, 1].legend(loc='best', fontsize=9)
    axes[0, 1].grid(True, alpha=0.3)

    # Configure Plot 3: Time to First Token
    axes[1, 0].set_xlabel('Concurrency', fontsize=11)
    axes[1, 0].set_ylabel('Time to First Token (ms)', fontsize=11)
    axes[1, 0].set_title('Time to First Token', fontsize=12, fontweight='bold')
    axes[1, 0].legend(loc='best', fontsize=9)
    axes[1, 0].grid(True, alpha=0.3)

    # Configure Plot 4: End-to-End Latency
    axes[1, 1].set_xlabel('Concurrency', fontsize=11)
    axes[1, 1].set_ylabel('Time per Output Token (ms)', fontsize=11)
    axes[1, 1].set_title('End-to-End Latency', fontsize=12, fontweight='bold')
    axes[1, 1].legend(loc='best', fontsize=9)
    axes[1, 1].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"✓ Plot saved to: {output_file}")

    # Also display the plot
    plt.show()

def main():
    print("Loading PCIe benchmark results...")
    data = load_results()

    print(f"Found {len(data)} configurations:")
    for config_key, results in data.items():
        print(f"  - {config_key}: {len(results)} data points")

    if not data:
        print("❌ No data found in bench_results/pcie/")
        return

    print("\nGenerating plots...")
    plot_results(data)

if __name__ == '__main__':
    main()
