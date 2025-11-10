#!/bin/bash

echo "===== CCometixLine Usage 字段调试工具 ====="
echo ""
echo "此脚本会运行 ccline 并显示详细的调试信息"
echo ""

# 检查 credentials 文件
echo "1. 检查 credentials 文件..."
if [ -f ~/.claude/.credentials.json ]; then
    echo "   ✓ credentials 文件存在"

    # 检查 JSON 格式
    if jq . ~/.claude/.credentials.json >/dev/null 2>&1; then
        echo "   ✓ JSON 格式正确"

        # 检查 token
        if jq -e '.claudeAiOauth.accessToken' ~/.claude/.credentials.json >/dev/null 2>&1; then
            TOKEN_LEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json | wc -c)
            echo "   ✓ accessToken 存在 (长度: $TOKEN_LEN)"
        else
            echo "   ✗ accessToken 不存在"
        fi
    else
        echo "   ✗ JSON 格式错误"
        echo "   内容："
        cat ~/.claude/.credentials.json
    fi
else
    echo "   ✗ credentials 文件不存在"
    exit 1
fi

echo ""
echo "2. 检查 usage 配置..."
if grep -A 1 'id = "usage"' ~/.claude/ccline/config.toml | grep -q 'enabled = true'; then
    echo "   ✓ usage 字段已启用"
else
    echo "   ✗ usage 字段未启用"
fi

echo ""
echo "3. 测试 API 连接..."
curl -s --connect-timeout 3 -I https://api.anthropic.com >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ 能连接到 api.anthropic.com"
else
    echo "   ✗ 无法连接到 api.anthropic.com"
fi

echo ""
echo "4. 删除旧缓存..."
if [ -f ~/.claude/ccline/.api_usage_cache.json ]; then
    rm ~/.claude/ccline/.api_usage_cache.json
    echo "   ✓ 已删除缓存"
else
    echo "   - 无缓存文件"
fi

echo ""
echo "5. 运行 ccline 并显示调试信息..."
echo "================================================================"
echo ""

# 设置调试模式并运行 ccline
export CCLINE_DEBUG=1

# 如果编译后的二进制在 target/release/，使用它
if [ -f ./target/release/ccometixline ]; then
    ./target/release/ccometixline 2>&1
elif [ -f ~/.claude/ccline/ccline ]; then
    ~/.claude/ccline/ccline 2>&1
else
    echo "错误：找不到 ccline 二进制文件"
    echo "请先编译：cargo build --release"
    exit 1
fi

echo ""
echo "================================================================"
echo ""
echo "6. 检查缓存是否创建..."
if [ -f ~/.claude/ccline/.api_usage_cache.json ]; then
    echo "   ✓ 缓存文件已创建"
    echo "   内容："
    cat ~/.claude/ccline/.api_usage_cache.json | jq . 2>/dev/null || cat ~/.claude/ccline/.api_usage_cache.json
else
    echo "   ✗ 缓存文件未创建 - API 调用可能失败了"
fi

echo ""
echo "===== 调试完成 ====="
echo ""
echo "如果看到 '[DEBUG] API call failed!'，常见原因："
echo "1. Token 无效或过期 - 重新登录 Claude Code"
echo "2. API 超时 - 增加配置文件中的 timeout 值"
echo "3. 网络问题 - 检查防火墙或代理设置"
echo "4. API 端点变化 - 查看具体的错误信息"
