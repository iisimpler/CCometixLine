#!/bin/bash

echo "===== 查找 Claude Code Credentials (备用方法) ====="
echo ""

echo "1. 检查常见的配置文件位置..."
echo ""

PATHS=(
    "$HOME/.claude/.credentials.json"
    "$HOME/.claude/credentials.json"
    "$HOME/Library/Application Support/claude-code/.credentials.json"
    "$HOME/Library/Application Support/claude-code/credentials.json"
    "$HOME/Library/Application Support/@anthropic-ai/claude-code/.credentials.json"
    "$HOME/Library/Preferences/com.anthropic.claude-code.plist"
)

for PATH_TO_CHECK in "${PATHS[@]}"; do
    if [ -f "$PATH_TO_CHECK" ]; then
        echo "  ✓ 找到: $PATH_TO_CHECK"

        # 检查是否为 JSON 文件
        if [[ "$PATH_TO_CHECK" == *.json ]]; then
            echo "  内容预览:"
            cat "$PATH_TO_CHECK" | head -20
            echo ""
        fi
    else
        echo "  ✗ 不存在: $PATH_TO_CHECK"
    fi
done

echo ""
echo "2. 搜索所有可能的 credentials 文件..."
echo ""

find "$HOME/.claude" "$HOME/Library/Application Support" -name "*credential*" -o -name "*auth*" 2>/dev/null | while read file; do
    echo "  找到: $file"
done

echo ""
echo "3. 检查 Claude Code 进程使用的文件..."
echo ""

# 查找 Claude Code 进程
CLAUDE_PID=$(pgrep -f "claude-code" | head -1)

if [ -n "$CLAUDE_PID" ]; then
    echo "  ✓ Claude Code 进程运行中 (PID: $CLAUDE_PID)"
    echo ""
    echo "  进程打开的文件（包含 claude 的）："
    lsof -p "$CLAUDE_PID" 2>/dev/null | grep -i claude | grep -v ".sock" | head -20
else
    echo "  - Claude Code 未运行"
    echo "  建议：先启动 Claude Code，然后再运行此脚本"
fi

echo ""
echo "===== 完成 ====="
