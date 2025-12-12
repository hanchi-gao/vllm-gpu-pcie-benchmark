#!/bin/bash

#######################################
# 將 Client Guide Markdown 文件轉換為 PDF
#
# 用法:
#   ./convert_to_pdf.sh
#
# 需求:
#   - pandoc
#   - texlive (for PDF generation)
#######################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "================================================"
echo "vLLM Client Guide - PDF 轉換工具"
echo "================================================"
echo

# 檢查 pandoc 是否已安裝
if ! command -v pandoc &> /dev/null; then
    echo "錯誤: pandoc 未安裝"
    echo
    echo "安裝方法:"
    echo "  Ubuntu/Debian: sudo apt-get install pandoc texlive-xetex texlive-fonts-recommended texlive-lang-chinese"
    echo "  macOS: brew install pandoc basictex"
    echo
    exit 1
fi

echo "✓ pandoc 已安裝: $(pandoc --version | head -1)"
echo

# 生成單個 PDF
generate_single_pdf() {
    local input_file=$1
    local output_file=$2
    local title=$3

    echo "正在轉換: $input_file → $output_file"

    pandoc "$input_file" \
        -o "$output_file" \
        --pdf-engine=xelatex \
        -V CJKmainfont="Noto Sans CJK TC" \
        -V geometry:margin=2cm \
        -V fontsize=11pt \
        --toc \
        --toc-depth=2 \
        --highlight-style=tango \
        -M title="$title" \
        -M date="$(date +%Y-%m-%d)" \
        2>&1

    if [ $? -eq 0 ]; then
        echo "✓ 成功生成: $output_file"
    else
        echo "✗ 生成失敗: $output_file"
        return 1
    fi
    echo
}

# 生成合併 PDF
generate_combined_pdf() {
    echo "正在生成合併版 PDF..."

    # 創建臨時合併文件
    cat > combined.md << 'EOF'
---
title: "vLLM 性能測試 - 客戶使用指南"
subtitle: "完整操作手冊"
author: "vLLM Performance Testing System"
date:
geometry: margin=2cm
fontsize: 11pt
CJKmainfont: "Noto Sans CJK TC"
toc: true
toc-depth: 2
---

\newpage

EOF

    # 添加各章節
    echo "# 第一章: Docker 環境設置" >> combined.md
    echo "" >> combined.md
    tail -n +2 01_DOCKER_SETUP.md >> combined.md
    echo "" >> combined.md
    echo "\\newpage" >> combined.md
    echo "" >> combined.md

    echo "# 第二章: vLLM 測試執行" >> combined.md
    echo "" >> combined.md
    tail -n +2 02_VLLM_TESTING.md >> combined.md
    echo "" >> combined.md
    echo "\\newpage" >> combined.md
    echo "" >> combined.md

    echo "# 第三章: 性能圖表說明" >> combined.md
    echo "" >> combined.md
    tail -n +2 03_PLOT_GENERATION.md >> combined.md

    # 轉換為 PDF
    pandoc combined.md \
        -o "vLLM_Client_Guide_Complete.pdf" \
        --pdf-engine=xelatex \
        -V CJKmainfont="Noto Sans CJK TC" \
        --highlight-style=tango \
        2>&1

    if [ $? -eq 0 ]; then
        echo "✓ 成功生成合併版 PDF: vLLM_Client_Guide_Complete.pdf"
        rm combined.md
    else
        echo "✗ 合併版 PDF 生成失敗"
        echo "保留臨時文件 combined.md 供檢查"
        return 1
    fi
    echo
}

# 選擇模式
echo "請選擇轉換模式:"
echo "  1) 生成單獨的 3 個 PDF 文件"
echo "  2) 生成合併的單一 PDF 文件"
echo "  3) 兩者都生成"
echo
read -p "請輸入選項 (1/2/3): " choice

case $choice in
    1)
        echo
        echo "模式 1: 生成單獨 PDF 文件"
        echo "================================================"
        echo
        generate_single_pdf "01_DOCKER_SETUP.md" "01_Docker環境設置.pdf" "Docker 環境設置指南"
        generate_single_pdf "02_VLLM_TESTING.md" "02_vLLM測試執行.pdf" "vLLM 測試執行指南"
        generate_single_pdf "03_PLOT_GENERATION.md" "03_性能圖表說明.pdf" "性能圖表說明文件"
        ;;
    2)
        echo
        echo "模式 2: 生成合併 PDF 文件"
        echo "================================================"
        echo
        generate_combined_pdf
        ;;
    3)
        echo
        echo "模式 3: 生成所有 PDF 文件"
        echo "================================================"
        echo
        echo "--- 生成單獨文件 ---"
        echo
        generate_single_pdf "01_DOCKER_SETUP.md" "01_Docker環境設置.pdf" "Docker 環境設置指南"
        generate_single_pdf "02_VLLM_TESTING.md" "02_vLLM測試執行.pdf" "vLLM 測試執行指南"
        generate_single_pdf "03_PLOT_GENERATION.md" "03_性能圖表說明.pdf" "性能圖表說明文件"
        echo
        echo "--- 生成合併文件 ---"
        echo
        generate_combined_pdf
        ;;
    *)
        echo "無效選項，退出"
        exit 1
        ;;
esac

echo "================================================"
echo "轉換完成！"
echo "================================================"
echo
echo "生成的 PDF 文件位置: $SCRIPT_DIR/"
ls -lh "$SCRIPT_DIR"/*.pdf 2>/dev/null
echo
