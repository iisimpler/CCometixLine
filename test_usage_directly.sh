#!/bin/bash

echo "===== 直接测试 Usage Segment ====="
echo ""

# 1. 确认 credentials 存在
if [ ! -f ~/.claude/.credentials.json ]; then
    echo "❌ credentials 文件不存在"
    exit 1
fi

echo "✓ credentials 文件存在"
echo ""

# 2. 创建一个最小的输入 JSON（模拟 Claude Code 传给 ccline 的数据）
cat > /tmp/ccline_test_input.json << 'EOF'
{
  "model": {
    "id": "claude-sonnet-4-5-20250929",
    "display_name": "Claude Sonnet 4.5"
  },
  "workspace": {
    "current_dir": "/tmp/test"
  },
  "transcript_path": "/tmp/test.jsonl"
}
EOF

echo "✓ 创建测试输入"
echo ""

# 3. 增加超时时间（在 config 中）
echo "修改配置，增加 timeout 到 10 秒..."
if [ -f ~/.claude/ccline/config.toml ]; then
    # 检查是否已经有 timeout 配置
    if grep -q "timeout.*=" ~/.claude/ccline/config.toml; then
        # 如果有，修改为 10
        sed -i.bak 's/timeout = [0-9]*/timeout = 10/g' ~/.claude/ccline/config.toml
        echo "✓ 已修改 timeout 为 10 秒"
    else
        echo "⚠ 未找到 timeout 配置，将使用默认值"
    fi
fi
echo ""

# 4. 删除缓存
rm -f ~/.claude/ccline/.api_usage_cache.json
echo "✓ 已删除旧缓存"
echo ""

# 5. 运行 ccline（启用调试模式）
echo "运行 ccline（启用调试模式）..."
echo "================================================================"

# 选择二进制文件
if [ -f ./target/release/ccometixline ]; then
    CCLINE_BIN=./target/release/ccometixline
elif [ -f ~/.claude/ccline/ccline ]; then
    CCLINE_BIN=~/.claude/ccline/ccline
else
    echo "❌ 找不到 ccline 二进制文件"
    exit 1
fi

# 运行并捕获输出
CCLINE_DEBUG=1 cat /tmp/ccline_test_input.json | $CCLINE_BIN 2>&1

echo ""
echo "================================================================"
echo ""

# 6. 检查缓存是否创建
if [ -f ~/.claude/ccline/.api_usage_cache.json ]; then
    echo "✓ 缓存文件已创建 - API 调用成功！"
    echo ""
    echo "缓存内容："
    cat ~/.claude/ccline/.api_usage_cache.json | jq . 2>/dev/null || cat ~/.claude/ccline/.api_usage_cache.json
    echo ""
    echo "🎉 Usage segment 应该能正常工作了！"
else
    echo "❌ 缓存文件未创建 - API 调用失败"
    echo ""
    echo "请查看上面的调试输出，找到具体错误原因"
    echo ""
    echo "常见问题："
    echo "1. 如果看到 'TimedOut' - 需要进一步增加 timeout"
    echo "2. 如果看到 '401' - token 可能过期了"
    echo "3. 如果看到 'Connection refused' - 检查网络"
fi

echo ""
echo "===== 测试完成 ====="
