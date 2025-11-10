#!/bin/bash

echo "===== 增加 Usage Segment 的 Timeout ====="
echo ""

CONFIG_FILE=~/.claude/ccline/config.toml

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 备份配置
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
echo "✓ 已备份配置文件到: ${CONFIG_FILE}.backup"

# 查找 usage segment 的 timeout 配置
# 在 [[segments]] 块中，找到 id = "usage" 之后的 timeout 值

# 使用 awk 来精确修改 usage segment 的 timeout
awk '
/^\[\[segments\]\]/ {
    in_segment = 1
    segment_buffer = $0 "\n"
    next
}

in_segment {
    segment_buffer = segment_buffer $0 "\n"

    if (/^id = "usage"/) {
        is_usage = 1
    }

    if (/^timeout = /) {
        if (is_usage) {
            print segment_buffer
            print "timeout = 10"
            in_segment = 0
            is_usage = 0
            segment_buffer = ""
            modified = 1
            next
        }
    }

    if (/^\[\[segments\]\]/ || /^$/ && NF == 0) {
        if (in_segment && segment_buffer != "") {
            print segment_buffer
            in_segment = 0
            is_usage = 0
            segment_buffer = ""
        }
        print
        next
    }
}

!in_segment {
    print
}

END {
    if (segment_buffer != "") {
        print segment_buffer
    }
}
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"

# 如果修改成功，替换原文件
if [ -f "${CONFIG_FILE}.tmp" ]; then
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    echo "✓ 已将 usage segment 的 timeout 更新为 10 秒"
    echo ""
    echo "验证配置:"
    echo ""
    grep -A 15 'id = "usage"' "$CONFIG_FILE" | grep -A 2 'timeout'
else
    echo "❌ 修改失败"
    exit 1
fi

echo ""
echo "===== 完成 ====="
echo ""
echo "现在可以运行: ./test_usage_directly.sh"
