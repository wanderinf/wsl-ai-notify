# WSL AI Notify

> Windows Toast notifications for AI CLI tools in WSL2

[![Install](https://img.shields.io/badge/Install-curl%20%7C%20bash-blue)](#installation)
[![License](https://img.shields.io/badge/License-MIT-green)](#license)
[![WSL2](https://img.shields.io/badge/Platform-WSL2-orange)](#prerequisites)

## Features

| Feature | Description |
|---------|-------------|
| 🔔 **Toast Notifications** | Native Windows notifications |
| 🖱️ **Click to Focus** | Click notification to bring terminal to front |
| 🏷️ **Smart Types** | Auto-detect done/waiting/error from content |
| 🌐 **Chinese Support** | Full Unicode/Chinese character support |
| 🔌 **Universal** | Works with OpenCode, Claude Code, Cursor, etc. |

## Prerequisites

- WSL2 (Windows Subsystem for Linux)
- Windows Terminal (recommended)
- `curl` and `unzip` installed

```bash
# Verify WSL2
cat /proc/sys/fs/binfmt_misc/WSLInterop && echo "✓ WSL2"
```

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/install.sh | bash
```

### Post-Install Step

After installation, **import the registry file**:

1. Open Windows Explorer
2. Navigate to `C:\Users\{your-username}\`
3. Double-click `wsl-notify.reg`
4. Click "Yes" to import

### Verify

```bash
notify --type=done "WSL AI Notify" "Installation complete!"
```

You should see a Windows toast notification.

## Usage

### Command Line

```bash
# Basic usage
notify "Title" "Message"

# Specify notification type
notify --type=done "Complete" "Generated login page · 3 files"
notify --type=waiting "Input Needed" "Please confirm the action"
notify --type=error "Error" "Build failed · 3/15 tests"

# notify-send compatible (auto type detection)
notify-send "Task complete" "3 files changed"
```

### Notification Types

| Type | Emoji | Trigger Keywords |
|------|:-----:|------------------|
| `done` | ✅ | 完成, finished, complete, done, success, 成功 |
| `waiting` | ⏳ | 等待, waiting, input, confirm, 需要, waiting for |
| `error` | ❌ | 错误, error, fail, 失败, failed |
| `warning` | ⚠️ | warning, warn |
| `info` | 💡 | (default) |

## AI CLI Tool Configuration

### OpenCode / oh-my-opencode

Edit `~/.config/opencode/oh-my-opencode.json`:

```json
{
  "notification": {
    "force_enable": true
  }
}
```

Or use jq:
```bash
jq '.notification.force_enable = true' ~/.config/opencode/oh-my-opencode.json > /tmp/oc.json && mv /tmp/oc.json ~/.config/opencode/oh-my-opencode.json
```

### Claude Code

Edit `~/.claude/settings.json` and add hooks:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/notify-send 'Claude Code' 'Waiting for your input'",
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/notify-send 'Claude Code' 'Task complete'",
            "async": true
          }
        ]
      }
    ]
  }
}
```

**Hook Types:**
- `Notification` - Triggered when waiting for user input
- `Stop` - Triggered when agent finishes responding

### Cursor CLI / Other Tools

No configuration required if they use `notify-send`.

## How It Works

```
AI CLI Tool (OpenCode/Claude Code)
        │
        ▼ calls notify-send
  ~/.local/bin/notify-send
        │
        ▼ smart type detection
  ~/.local/bin/notify
        │
        ▼ PowerShell Toast API
  Windows Notification Center
        │
        ▼ user clicks notification
  wslfocus:// protocol
        │
        ▼
  nircmd activates Windows Terminal
```

## Project Structure

```
wsl-ai-notify/
├── AGENTS.md              # AI agent installation guide
├── README.md              # This file
├── install.sh             # One-click installer
├── bin/
│   ├── notify             # Main notification script
│   └── notify-send        # Compatibility wrapper
└── windows/
    ├── focus-terminal.vbs # Click handler (VBScript)
    └── wsl-notify.reg     # Protocol registration
```

## Troubleshooting

<details>
<summary>Notification not showing</summary>

```bash
# Check PATH
which notify notify-send

# Test PowerShell directly
powershell.exe -Command "Write-Host 'PowerShell OK'"

# Check if scripts are executable
ls -la ~/.local/bin/notify*
```
</details>

<details>
<summary>Click doesn't focus terminal</summary>

1. Verify registry was imported: Open `regedit` and check `HKEY_CLASSES_ROOT\wslfocus`
2. Verify nircmd exists:
   ```bash
   ls /mnt/c/Users/*/.local/bin/nircmd.exe
   ```
3. Test manually:
   ```cmd
   C:\Users\{user}\.local\bin\nircmd.exe win activate process "WindowsTerminal.exe"
   ```
</details>

<details>
<summary>Claude Code not showing notifications</summary>

1. Verify hooks are configured in `~/.claude/settings.json`
2. Check hook syntax matches the schema
3. Test manually:
   ```bash
   ~/.local/bin/notify-send "Claude Code" "Test"
   ```
</details>

<details>
<summary>Chinese characters garbled</summary>

The scripts use base64 encoding for Unicode support. Test:
```bash
echo "测试中文" | base64
```
</details>

## Uninstall

```bash
# Remove scripts
rm -f ~/.local/bin/notify ~/.local/bin/notify-send

# Remove PATH addition from ~/.bashrc (optional)
# sed -i '/export PATH="\$HOME\/.local\/bin/d' ~/.bashrc

# Windows cleanup (manual):
# - Delete HKEY_CLASSES_ROOT\wslfocus in regedit
# - Delete C:\Users\{user}\.local\bin\nircmd.exe
# - Delete C:\Users\{user}\.local\bin\focus-terminal.vbs
```

## For AI Agents

If you're an AI agent installing this for a user, see [AGENTS.md](./AGENTS.md) for step-by-step instructions optimized for automated installation.

## License

MIT

---

**Made with ❤️ for WSL + AI CLI users**
