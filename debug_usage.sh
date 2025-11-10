#!/bin/bash

echo "===== CCometixLine Usage 字段诊断工具 ====="
echo ""

# 1. 检查配置文件
echo "1. 检查配置文件是否存在..."
if [ -f ~/.claude/ccline/config.toml ]; then
    echo "   ✓ 配置文件存在"
    echo ""
    echo "   检查 usage 字段是否启用..."
    if grep -A 1 'id = "usage"' ~/.claude/ccline/config.toml | grep -q 'enabled = true'; then
        echo "   ✓ usage 字段已启用"
    else
        echo "   ✗ usage 字段未启用"
        echo "   解决方法：编辑 ~/.claude/ccline/config.toml，将 usage 段的 enabled 改为 true"
    fi
else
    echo "   ✗ 配置文件不存在"
    echo "   解决方法：运行 'ccline --init' 初始化配置"
fi

echo ""

# 2. 检查 credentials 文件
echo "2. 检查 Claude Code credentials..."
CRED_FILE=~/.claude/.credentials.json

if [ -f "$CRED_FILE" ]; then
    echo "   ✓ credentials 文件存在: $CRED_FILE"

    # 检查是否包含 OAuth token
    if grep -q "claudeAiOauth" "$CRED_FILE"; then
        echo "   ✓ 找到 claudeAiOauth 配置"

        # 检查 accessToken 是否存在且不为空
        if grep -q '"accessToken"' "$CRED_FILE" && ! grep -q '"accessToken": ""' "$CRED_FILE"; then
            echo "   ✓ accessToken 存在"
        else
            echo "   ✗ accessToken 为空或不存在"
            echo "   解决方法：请在 Claude Code 中重新登录"
        fi
    else
        echo "   ✗ 未找到 claudeAiOauth 配置"
        echo "   解决方法：请在 Claude Code 中登录 Claude.ai 账号"
    fi
else
    echo "   ✗ credentials 文件不存在: $CRED_FILE"
    echo ""
    echo "   可能的原因："
    echo "   - 您还未在 Claude Code 中登录 Claude.ai 账号"
    echo "   - credentials 文件在其他位置"
    echo ""
    echo "   解决方法："
    echo "   1. 打开 Claude Code"
    echo "   2. 确保已登录 Claude.ai 账号（不是 Claude Code 账号）"
    echo "   3. 检查是否能在 Claude Code 中看到您的 usage 限制"
fi

echo ""

# 3. 检查网络连接
echo "3. 检查 Anthropic API 连接..."
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 3 -I https://api.anthropic.com &> /dev/null; then
        echo "   ✓ 能够连接到 api.anthropic.com"
    else
        echo "   ✗ 无法连接到 api.anthropic.com"
        echo "   解决方法：检查网络连接或代理设置"
    fi
else
    echo "   - 跳过（curl 未安装）"
fi

echo ""

# 4. 检查缓存
echo "4. 检查 usage 缓存..."
CACHE_FILE=~/.claude/ccline/.api_usage_cache.json

if [ -f "$CACHE_FILE" ]; then
    echo "   ✓ 缓存文件存在: $CACHE_FILE"
    echo "   缓存内容："
    cat "$CACHE_FILE" | python3 -m json.tool 2>/dev/null || cat "$CACHE_FILE"
else
    echo "   - 缓存文件不存在（首次使用时正常）"
fi

echo ""
echo "===== 诊断完成 ====="
echo ""
echo "如果所有检查都通过，但 usage 仍不显示，请运行："
echo "  ccline 2>&1 | tee debug.log"
echo "然后查看 debug.log 中的错误信息"
