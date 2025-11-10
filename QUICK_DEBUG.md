# Usage 字段快速调试指南

## 当前情况

您已经确认：
- ✅ credentials 文件存在且包含有效的 token
- ✅ config.toml 中 usage 已启用
- ❌ usage 字段仍不显示

这说明问题在于 **API 调用阶段**。

## 快速诊断

在您的 Mac 终端运行以下命令：

### 方式一：使用测试脚本（推荐）

```bash
# 1. 拉取最新代码
git pull

# 2. 重新编译
cargo build --release

# 3. 运行调试脚本
./test_usage_debug.sh
```

这个脚本会：
- 验证所有配置
- 运行 ccline 并显示详细的调试信息
- 帮您定位具体问题

### 方式二：手动测试

```bash
# 1. 删除旧缓存
rm ~/.claude/ccline/.api_usage_cache.json

# 2. 启用调试模式运行
CCLINE_DEBUG=1 ~/.claude/ccline/ccline

# 或使用刚编译的版本
CCLINE_DEBUG=1 ./target/release/ccometixline
```

## 查看调试输出

启用 `CCLINE_DEBUG=1` 后，会看到类似这样的输出：

### 成功案例：
```
[DEBUG] Successfully got OAuth token (length: 123)
[DEBUG] API base URL: https://api.anthropic.com
[DEBUG] Cache duration: 180s
[DEBUG] Timeout: 2s
[DEBUG] Fetching fresh data from API...
[DEBUG] API URL: https://api.anthropic.com/api/oauth/usage
[DEBUG] User-Agent: claude-code/2.0.36
[DEBUG] API response status: 200
[DEBUG] API call successful!
[DEBUG] 5-hour utilization: 42.5
[DEBUG] 7-day utilization: 38.2
```

### 失败案例及解决方法：

#### 1. Token 获取失败
```
[DEBUG] Failed to get OAuth token
```
**解决**：检查 `~/.claude/.credentials.json` 文件是否存在且格式正确

#### 2. API 请求超时
```
[DEBUG] API request error: Transport(Error { kind: TimedOut })
```
**解决**：增加 timeout 值
```toml
# 编辑 ~/.claude/ccline/config.toml
[segments.options]
timeout = 5  # 从 2 秒增加到 5 秒
```

#### 3. API 返回非 200 状态
```
[DEBUG] Non-200 status code: 401
[DEBUG] Response body: {"error": "Invalid authentication"}
```
**解决**：Token 无效或过期，需要重新登录 Claude Code
```bash
# 重新从 Keychain 导出
security find-generic-password -s "Claude Code-credentials" -w > ~/.claude/.credentials.json
```

#### 4. 网络连接问题
```
[DEBUG] API request error: Transport(Error { kind: ConnectionRefused })
```
**解决**：
- 检查网络连接
- 检查是否需要代理
- 尝试手动测试：`curl -I https://api.anthropic.com`

#### 5. JSON 解析失败
```
[DEBUG] API response status: 200
[DEBUG] Failed to parse API response: ...
```
**解决**：API 响应格式可能变化了，需要查看完整错误信息

## 常见问题

### Q: 为什么 TUI 预览能显示，但实际使用不行？

A: TUI 预览使用的是模拟数据，不会真正调用 API。实际使用时需要调用 Anthropic API 获取真实数据。

### Q: `/usage` 命令能用，为什么 ccline 不行？

A: Claude Code 和 ccline 可能使用不同的方式访问 API：
- Claude Code 可能有内置的 token 管理
- ccline 需要从文件或 Keychain 读取 token
- API 端点或请求格式可能略有不同

### Q: Token 会过期吗？

A: 是的。OAuth token 会过期。如果 ccline 突然不工作了：
```bash
# 重新导出 token
security find-generic-password -s "Claude Code-credentials" -w > ~/.claude/.credentials.json
```

## 下一步

1. 运行 `./test_usage_debug.sh`
2. 查看调试输出，找到具体错误
3. 根据错误类型应用对应的解决方法
4. 如果仍无法解决，请将完整的调试输出发给我

## 其他调试技巧

### 手动测试 API

```bash
# 从 credentials 文件读取 token
TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json)

# 手动调用 API
curl -H "Authorization: Bearer $TOKEN" \
     -H "anthropic-beta: oauth-2025-04-20" \
     -H "User-Agent: claude-code/2.0.36" \
     https://api.anthropic.com/api/oauth/usage

# 如果返回 JSON 数据，说明 token 有效
# 如果返回 401，说明 token 无效或过期
```

### 检查代理设置

```bash
# 查看 Claude Code 的代理配置
cat ~/.claude/settings.json | jq '.env.HTTPS_PROXY'

# 如果有代理，确保网络畅通
```

### 查看缓存

```bash
# 查看缓存内容
cat ~/.claude/ccline/.api_usage_cache.json | jq .

# 查看缓存时间
jq -r '.cached_at' ~/.claude/ccline/.api_usage_cache.json
```
