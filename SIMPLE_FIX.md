# Usage 字段简单修复指南

## 问题确认

您已经验证：
- ✅ curl 手动调用 API 成功
- ✅ JSON 解析测试通过
- ✅ credentials 文件存在且有效

**结论：问题很可能是 API 超时（默认 2 秒太短）**

## 快速修复

### 步骤 1：增加 Timeout

编辑配置文件：

```bash
nano ~/.claude/ccline/config.toml
```

找到 usage segment 的配置（大约在 84-104 行），将 `timeout = 2` 改为 `timeout = 10`：

```toml
[[segments]]
id = "usage"
enabled = true

[segments.icon]
plain = "📊"
nerd_font = "󰪞"

[segments.colors.icon]
c16 = 14

[segments.colors.text]
c16 = 14

[segments.styles]
text_bold = false

[segments.options]
timeout = 10              # ← 改这里，从 2 改为 10
cache_duration = 180
api_base_url = "https://api.anthropic.com"
```

保存文件（Ctrl+O, Enter, Ctrl+X）。

### 步骤 2：测试

```bash
# 删除旧缓存
rm -f ~/.claude/ccline/.api_usage_cache.json

# 启用调试模式测试
CCLINE_DEBUG=1 ~/.claude/ccline/ccline

# 或者如果刚编译的：
CCLINE_DEBUG=1 ./target/release/ccometixline
```

查看输出中是否有：
```
[DEBUG] API call successful!
```

### 步骤 3：在 Claude Code 中测试

重启 Claude Code，usage 字段应该会显示。

## 如果还是不行

### 方案 A：进一步增加 timeout

有些网络环境可能需要更长时间：

```toml
timeout = 20  # 增加到 20 秒
```

### 方案 B：检查是否有代理

如果您使用代理，需要在 Claude Code 的 settings.json 中配置：

```bash
nano ~/.claude/settings.json
```

添加：

```json
{
  "env": {
    "HTTPS_PROXY": "http://your-proxy:port"
  }
}
```

### 方案 C：查看详细错误

运行诊断脚本查看具体错误：

```bash
./test_usage_directly.sh
```

这会显示详细的调试信息，包括：
- Token 长度
- API URL
- 请求状态
- 响应内容
- 具体错误信息

## 验证成功

成功后，您应该看到：

1. **命令行输出**（带 CCLINE_DEBUG=1）：
```
[DEBUG] Successfully got OAuth token (length: 234)
[DEBUG] Fetching fresh data from API...
[DEBUG] API URL: https://api.anthropic.com/api/oauth/usage
[DEBUG] API response status: 200
[DEBUG] API call successful!
[DEBUG] 5-hour utilization: 8.0
[DEBUG] 7-day utilization: 18.0
```

2. **缓存文件创建**：
```bash
cat ~/.claude/ccline/.api_usage_cache.json
```

应该显示类似：
```json
{
  "five_hour_utilization": 8.0,
  "seven_day_utilization": 18.0,
  "resets_at": "2025-11-13T01:59:59.571382+00:00",
  "cached_at": "2025-11-10T08:00:00Z"
}
```

3. **状态栏显示**：
```
🤖 Sonnet 4.5 | 📁 project | 🌿 main | ⚡ 15% | 📊 8% · 11-10-10
                                                  ↑    ↑      ↑
                                            usage icon | 5小时使用率 | 重置时间
```

## 为什么会超时？

- **默认 2 秒** 对于网络延迟高的环境可能不够
- **API 调用** 需要 TLS 握手、DNS 解析等开销
- **网络环境** 不同会导致响应时间差异很大

手动 curl 可能看起来很快，但在程序中：
- 需要建立新的 TCP 连接
- 需要 TLS 握手
- 可能有 DNS 缓存差异
- 程序中的超时检查更严格

增加到 10-20 秒是安全的，因为：
- 只在首次调用或缓存过期时才会调用 API
- 后续会使用缓存（默认 180 秒）
- 不会影响状态栏刷新速度

## 最终确认

修改后，在 Claude Code 中应该能看到类似这样的状态栏：

```
📊 8% · 11-13-1
```

其中：
- `8%` 是您的 5 小时使用率
- `11-13-1` 是重置时间（11月13日1点）

如果看到了，说明成功了！🎉
