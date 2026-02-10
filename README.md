# WSL AI Notify

为 WSL 中的 AI CLI 工具提供 Windows 原生通知。

## 功能

- ✅ Windows Toast 通知（支持中文）
- ✅ 点击通知自动跳转到终端
- ✅ 智能推断通知类型（完成/等待/错误）
- ✅ 显示项目名、终端、时间戳
- ✅ 支持 OpenCode、Claude Code 等所有 AI CLI 工具

## 安装

```bash
# 一键安装
curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/install.sh | bash
```

安装完成后：
1. 双击 `C:\Users\{你的用户名}\wsl-notify.reg` 导入注册表
2. 重启终端

## 使用

### 命令行

```bash
# 基础用法
notify "标题" "消息内容"

# 指定类型
notify --type=done "任务完成" "生成登录页面"
notify --type=waiting "等待输入" "需要确认"
notify --type=error "错误" "构建失败"

# notify-send 兼容（自动推断类型）
notify-send "任务完成" "3 files changed"
```

### AI CLI 工具自动通知

#### OpenCode / oh-my-opencode

在 `~/.config/opencode/oh-my-opencode.json` 中启用：

```json
{
  "notification": {
    "force_enable": true
  }
}
```

#### Claude Code

Claude Code 会自动调用 `notify-send`，无需额外配置。

## 通知类型

| 类型 | Emoji | 触发关键词 |
|------|-------|-----------|
| done | ✅ | 完成, finished, complete, success |
| waiting | ⏳ | 等待, waiting, input, confirm |
| error | ❌ | 错误, error, fail, failed |
| warning | ⚠️ | warning, warn |
| info | 💡 | 默认 |

## 手动安装

如果一键安装失败，可以手动安装：

```bash
# 1. 下载脚本
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/bin/notify -o ~/.local/bin/notify
curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/bin/notify-send -o ~/.local/bin/notify-send
chmod +x ~/.local/bin/notify ~/.local/bin/notify-send

# 2. 下载 nircmd 到 Windows
curl -sL "https://www.nirsoft.net/utils/nircmd-x64.zip" -o /tmp/nircmd.zip
unzip /tmp/nircmd.zip -d /tmp/nircmd
WIN_USER=$(cmd.exe /c "echo %USERNAME%" | tr -d '\r')
cp /tmp/nircmd/nircmd.exe "/mnt/c/Users/$WIN_USER/.local/bin/"

# 3. 创建 VBScript 和注册表（见 install.sh）

# 4. 导入注册表
# 双击 C:\Users\{用户名}\wsl-notify.reg
```

## 卸载

```bash
rm -f ~/.local/bin/notify ~/.local/bin/notify-send
# 删除注册表项: HKEY_CLASSES_ROOT\wslfocus
# 删除 C:\Users\{用户名}\.local\bin\nircmd.exe
# 删除 C:\Users\{用户名}\.local\bin\focus-terminal.vbs
```

## 支持的终端

- Windows Terminal ✅
- 其他终端可能需要修改 `focus-terminal.vbs`

## License

MIT
