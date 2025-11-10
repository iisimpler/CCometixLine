# macOS 上启用 Usage 字段完整指南

## 问题背景

您的情况：
- ✅ macOS 系统
- ✅ 通过 `brew install claude-code` 安装 Claude Code v2.0.36
- ✅ 已通过 `/login` 登录成功
- ✅ `/usage` 命令能正常执行
- ❌ `~/.claude/.credentials.json` 文件不存在
- ❌ ccline 的 usage 字段不显示

## 原因分析

Claude Code v2.x 在 macOS 上可能将 credentials 存储在以下位置之一：
1. **macOS Keychain** - 最可能的位置
2. **不同的文件路径** - 如 `~/Library/Application Support/claude-code/`
3. **不同的服务名** - Keychain 中使用的服务名可能不同

## 解决方案

### 步骤 1：运行诊断脚本

在您的 Mac 上，在项目目录运行：

```bash
chmod +x debug_macos_credentials.sh
./debug_macos_credentials.sh
```

这个脚本会：
1. 尝试多个可能的 Keychain 服务名
2. 如果找到 credentials，会提示您保存到文件
3. 自动配置让 ccline 能读取

### 步骤 2：（备用）手动查找 credentials

如果脚本没有找到，运行备用脚本：

```bash
chmod +x find_credentials_alternative.sh
./find_credentials_alternative.sh
```

这会搜索所有可能的文件位置。

### 步骤 3：使用 Keychain Access 手动查找

1. 打开 **Keychain Access.app**（钥匙串访问）
2. 在搜索框输入 `claude`
3. 查看所有包含 "claude" 的条目
4. 找到与 Claude Code 相关的条目，记下：
   - **名称**（服务名）
   - **账户**
   - 双击条目，查看内容

5. 如果找到 JSON 格式的内容，复制并保存到 `~/.claude/.credentials.json`：

```bash
# 创建目录
mkdir -p ~/.claude

# 编辑文件
nano ~/.claude/.credentials.json

# 粘贴从 Keychain 复制的 JSON 内容，应该类似：
{
  "claudeAiOauth": {
    "accessToken": "sk-ant-...",
    "refreshToken": "...",
    "expiresAt": 1234567890,
    "scopes": ["oauth"],
    "subscriptionType": "pro"
  }
}

# 保存并设置权限
chmod 600 ~/.claude/.credentials.json
```

### 步骤 4：更新 ccline

如果您找到了 credentials，但服务名不在我们的列表中，有两个选择：

#### 选项 A：使用更新后的代码（推荐）

我已经更新了代码，现在会尝试以下服务名：
- `Claude Code-credentials`
- `claude-code-credentials`
- `Claude Code`
- `claude-code`
- `anthropic-ai/claude-code`
- `@anthropic-ai/claude-code`

重新编译：

```bash
cargo build --release

# 复制到 Claude 目录
cp target/release/ccometixline ~/.claude/ccline/ccline
chmod +x ~/.claude/ccline/ccline
```

#### 选项 B：手动添加服务名

如果您的服务名不在上述列表中，编辑 `src/utils/credentials.rs`：

```rust
let service_names = vec![
    "Claude Code-credentials",
    "claude-code-credentials",
    "您找到的服务名",  // ← 添加这里
    // ...
];
```

然后重新编译。

### 步骤 5：验证

```bash
# 运行 ccline
~/.claude/ccline/ccline

# 应该能看到 usage 字段
```

## 高级选项：从进程中提取 token

如果以上方法都不行，可以从运行中的 Claude Code 进程获取 token：

```bash
# 1. 启动 Claude Code
# 2. 运行 /usage 命令
# 3. 在另一个终端，捕获网络请求

# 方法 1：使用 mitmproxy (需要安装)
mitmproxy

# 方法 2：检查 Claude Code 进程打开的文件
lsof -p $(pgrep -f claude-code | head -1) | grep -i claude
```

## 代码改进

我已经对代码进行了以下改进：

### 1. 支持多个 Keychain 服务名
`src/utils/credentials.rs:31-76` - 现在会尝试 6 个不同的服务名

### 2. 支持多个文件路径
`src/utils/credentials.rs:91-117` - 现在会检查：
- `~/.claude/.credentials.json`
- `~/.claude/credentials.json`
- `~/Library/Application Support/claude-code/.credentials.json`
- `~/Library/Application Support/@anthropic-ai/claude-code/.credentials.json`

## 常见问题

### Q: 为什么 `/usage` 能用但 ccline 不行？

A: Claude Code 可能直接从 Keychain 读取（或使用其他方法），而 ccline 需要通过 `security` 命令访问。两者使用的服务名或路径可能不同。

### Q: 我找到了 credentials，但格式不对怎么办？

A: 确保 JSON 格式正确，必须包含 `claudeAiOauth.accessToken` 字段：

```json
{
  "claudeAiOauth": {
    "accessToken": "your-token-here"
  }
}
```

### Q: Token 会过期吗？

A: 是的。如果 ccline 突然不工作了，可能是 token 过期。重新登录 Claude Code 即可。

### Q: 安全性如何？

A:
- Keychain 是 macOS 的安全存储，受系统保护
- credentials 文件应设置为 `600` 权限（仅所有者可读写）
- 不要分享 token 或提交到 git

## 下一步

完成设置后：

1. 确认 usage 字段显示：`ccline`
2. 配置到 Claude Code：编辑 `~/.claude/settings.json`
3. 享受完整的状态栏信息！

如果仍有问题，请运行诊断脚本并分享输出。
