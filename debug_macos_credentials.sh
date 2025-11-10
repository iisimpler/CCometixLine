#!/bin/bash

echo "===== macOS Claude Code Credentials 诊断工具 ====="
echo ""

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "警告：此脚本仅适用于 macOS"
    echo "当前系统：$OSTYPE"
    exit 1
fi

echo "1. 检查 macOS Keychain 中的 Claude Code credentials..."
echo ""

# 尝试不同的可能的服务名
SERVICE_NAMES=(
    "Claude Code-credentials"
    "claude-code-credentials"
    "Claude Code"
    "claude-code"
    "anthropic-ai/claude-code"
    "@anthropic-ai/claude-code"
)

USER=$(whoami)

for SERVICE in "${SERVICE_NAMES[@]}"; do
    echo "  尝试服务名: $SERVICE"
    RESULT=$(security find-generic-password -a "$USER" -s "$SERVICE" -w 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
        echo "  ✓ 找到 credentials！"
        echo ""
        echo "  服务名: $SERVICE"
        echo "  账户名: $USER"
        echo ""

        # 尝试解析 JSON
        if echo "$RESULT" | jq . >/dev/null 2>&1; then
            echo "  Credentials 内容（JSON 格式）："
            echo "$RESULT" | jq .

            # 检查是否包含 claudeAiOauth
            if echo "$RESULT" | jq -e '.claudeAiOauth.accessToken' >/dev/null 2>&1; then
                echo ""
                echo "  ✓ 找到 claudeAiOauth.accessToken"

                # 保存到文件以供代码使用
                echo ""
                echo "2. 是否要将此 credentials 保存到 ~/.claude/.credentials.json？"
                echo "   这样 ccline 就能读取它了。"
                echo ""
                read -p "   保存？(y/n): " -n 1 -r
                echo

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    mkdir -p ~/.claude
                    echo "$RESULT" > ~/.claude/.credentials.json
                    chmod 600 ~/.claude/.credentials.json
                    echo "   ✓ 已保存到 ~/.claude/.credentials.json"
                    echo ""
                    echo "   现在可以运行 ccline 测试 usage 字段了！"
                fi
            fi
        else
            echo "  警告：内容不是有效的 JSON 格式"
            echo "  内容预览：${RESULT:0:100}..."
        fi

        echo ""
        echo "===== 找到可用的 credentials ====="
        echo ""
        echo "下一步："
        echo "1. 如果已保存到文件，直接运行 ccline 测试"
        echo "2. 或者修改源码 src/utils/credentials.rs，将服务名改为: $SERVICE"
        exit 0
    else
        echo "  ✗ 未找到"
    fi
done

echo ""
echo "===== 未找到 credentials ====="
echo ""
echo "可能的原因："
echo "1. Claude Code 使用了不同的 keychain 服务名"
echo "2. Credentials 存储在其他位置"
echo ""
echo "诊断步骤："
echo ""
echo "方法 1：查找所有 Claude 相关的 keychain 条目"
echo "  运行以下命令："
echo "  security dump-keychain | grep -i claude"
echo ""
echo "方法 2：查看 Claude Code 的配置目录"
echo "  ls -la ~/.claude/"
echo "  ls -la ~/Library/Application Support/claude-code/"
echo ""
echo "方法 3：使用 Keychain Access 应用"
echo "  1. 打开 Keychain Access.app"
echo "  2. 搜索 'claude'"
echo "  3. 查看找到的条目的名称和内容"
echo ""
echo "方法 4：运行 Claude Code 并捕获 token"
echo "  在 Claude Code 中运行 /usage 命令时，可以从进程内存或网络请求中获取 token"
