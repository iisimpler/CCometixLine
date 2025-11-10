# Usage 字段故障排除指南

## 问题症状

- TUI 预览中能看到 usage 字段
- 配置文件中 usage 已启用（`enabled = true`）
- 在 Claude Code 中使用时，usage 字段不显示
- 其他字段（model、directory、git 等）正常显示

## 根本原因

**usage 字段需要 OAuth credentials 才能调用 Anthropic API**

源码位置：`src/core/segments/usage.rs:185`
```rust
fn collect(&self, _input: &InputData) -> Option<SegmentData> {
    let token = credentials::get_oauth_token()?;  // ← 这里如果返回 None，整个 segment 返回 None
    // ...
}
```

当 `get_oauth_token()` 返回 `None` 时，usage segment 不会显示。

## 诊断步骤

### 1. 运行诊断脚本

```bash
./debug_usage.sh
```

### 2. 检查 credentials 文件

```bash
ls -la ~/.claude/.credentials.json
```

如果文件不存在，说明：
- 您还未在 Claude Code 中登录 Claude.ai 账号
- 或者 credentials 存储在其他位置（如 macOS Keychain）

### 3. 检查 credentials 文件内容

```bash
cat ~/.claude/.credentials.json
```

正确的格式应该是：
```json
{
  "claudeAiOauth": {
    "accessToken": "your-token-here",
    "refreshToken": "...",
    "expiresAt": 1234567890,
    "scopes": ["oauth"],
    "subscriptionType": "pro"
  }
}
```

## 解决方案

### 方案 1：在 Claude Code 中登录 Claude.ai（推荐）

1. 打开 Claude Code
2. 查看是否已登录 Claude.ai 账号
3. 如果未登录，使用 OAuth 登录 Claude.ai
4. 登录后，`~/.claude/.credentials.json` 应该会自动创建

**验证方法**：在 Claude Code 中运行 `/usage` 命令，如果能看到使用量信息，说明已成功登录。

### 方案 2：手动获取 OAuth Token（临时测试）

如果您需要快速测试，可以从浏览器中获取 token：

1. 在浏览器中访问 https://claude.ai
2. 登录您的账号
3. 打开浏览器开发者工具（F12）
4. 切换到 Network 标签
5. 刷新页面或发送一条消息
6. 查找请求头中的 `Authorization: Bearer xxx` 或 Cookie 中的 session token
7. 使用提供的脚本创建 credentials 文件：

```bash
chmod +x create_test_credentials.sh
./create_test_credentials.sh
```

**注意**：手动创建的 token 会过期，需要定期更新。

### 方案 3：修改代码支持环境变量（开发者选项）

如果您想要更灵活的配置，可以修改 `src/utils/credentials.rs`，添加环境变量支持：

```rust
pub fn get_oauth_token() -> Option<String> {
    // 优先使用环境变量
    if let Ok(token) = std::env::var("CLAUDE_OAUTH_TOKEN") {
        return Some(token);
    }

    // 其他现有逻辑...
    if cfg!(target_os = "macos") {
        get_oauth_token_macos()
    } else {
        get_oauth_token_file()
    }
}
```

然后在 Claude Code 的 `settings.json` 中配置：

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/ccline/ccline",
    "padding": 0
  },
  "env": {
    "CLAUDE_OAUTH_TOKEN": "your-token-here"
  }
}
```

## 其他可能的问题

### API 请求失败

即使有 token，API 请求也可能失败。检查：

1. **网络连接**：
```bash
curl -I https://api.anthropic.com
```

2. **代理设置**：
如果使用代理，确保在 `~/.claude/settings.json` 中配置：
```json
{
  "env": {
    "HTTPS_PROXY": "http://your-proxy:port",
    "HTTP_PROXY": "http://your-proxy:port"
  }
}
```

3. **API 超时**：
默认超时是 2 秒。如果网络慢，可以在配置中增加：
```toml
[segments.options]
timeout = 5  # 增加到 5 秒
```

### 缓存问题

usage 数据会缓存 3 分钟（默认 180 秒）。如果怀疑缓存有问题：

```bash
# 删除缓存
rm ~/.claude/ccline/.api_usage_cache.json

# 再次运行 ccline
ccline
```

### 查看详细错误信息

运行 ccline 并查看错误输出：

```bash
ccline 2>&1 | tee debug.log
```

## 总结

**最常见的问题是 credentials 文件不存在**。解决方法：

1. ✅ 在 Claude Code 中登录 Claude.ai 账号
2. ✅ 确认 `~/.claude/.credentials.json` 存在
3. ✅ 确认配置文件中 usage enabled = true
4. ✅ 测试网络连接到 api.anthropic.com

如果以上都正常但仍不显示，请提交 issue 并附上 debug.log。

## 相关文件

- 配置文件：`~/.claude/ccline/config.toml`
- Credentials：`~/.claude/.credentials.json`
- 缓存文件：`~/.claude/ccline/.api_usage_cache.json`
- 源码：`src/core/segments/usage.rs`
- 认证逻辑：`src/utils/credentials.rs`
