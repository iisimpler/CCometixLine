#!/bin/bash

# 创建测试用的 credentials 文件
# 注意：这需要您有有效的 Claude.ai OAuth token

echo "===== 创建测试 credentials 文件 ====="
echo ""
echo "警告：此脚本会创建 ~/.claude/.credentials.json 文件"
echo "如果您已有此文件，它将被备份到 ~/.claude/.credentials.json.backup"
echo ""

CRED_FILE=~/.claude/.credentials.json

# 备份现有文件
if [ -f "$CRED_FILE" ]; then
    echo "备份现有文件..."
    cp "$CRED_FILE" "${CRED_FILE}.backup"
fi

# 提示用户输入 token
echo "请输入您的 Claude.ai OAuth access token："
echo "(您可以从浏览器的开发者工具中获取，访问 claude.ai 后查看 Network 请求)"
read -r TOKEN

if [ -z "$TOKEN" ]; then
    echo "错误：未输入 token"
    exit 1
fi

# 创建 credentials 文件
cat > "$CRED_FILE" << EOF
{
  "claudeAiOauth": {
    "accessToken": "$TOKEN",
    "refreshToken": null,
    "expiresAt": null,
    "scopes": ["oauth"],
    "subscriptionType": "pro"
  }
}
EOF

chmod 600 "$CRED_FILE"

echo ""
echo "✓ credentials 文件已创建: $CRED_FILE"
echo ""
echo "现在可以运行 ccline 测试 usage 字段了"
