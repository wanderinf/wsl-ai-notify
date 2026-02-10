# AGENTS.md - AI Agent Installation Guide

> This file is optimized for AI agents (Claude, GPT, Gemini, etc.) to understand and install this tool.

## What This Tool Does

Enables Windows Toast notifications for AI CLI tools running in WSL2:
- Shows notifications when tasks complete or need user input
- Click notification to focus the terminal window
- Works with OpenCode, Claude Code, Cursor CLI, and any tool using `notify-send`

## Prerequisites Check

Before installing, verify:

```bash
# Must be WSL2
cat /proc/sys/fs/binfmt_misc/WSLInterop && echo "WSL2 detected ✓" || echo "NOT WSL2 ✗"

# Must have powershell.exe accessible
powershell.exe -Command "Write-Host 'PowerShell OK'" && echo "PowerShell accessible ✓"

# Must have curl and unzip
which curl unzip && echo "Dependencies OK ✓"
```

## Installation Steps (Execute in Order)

### Step 1: Download and Run Installer

```bash
curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/install.sh | bash
```

### Step 2: Import Windows Registry

The installer creates a `.reg` file. User must double-click it:

```
Location: C:\Users\{username}\wsl-notify.reg
Action: Double-click to import
```

If automating, inform user:
> "Please open Windows Explorer and double-click the file `wsl-notify.reg` in your user folder to complete installation."

### Step 3: Configure AI CLI Tools

#### For OpenCode / oh-my-opencode

```bash
# Check if oh-my-opencode is installed
if [[ -f ~/.config/opencode/oh-my-opencode.json ]]; then
    # Enable notifications
    jq '.notification.force_enable = true' ~/.config/opencode/oh-my-opencode.json > /tmp/oc.json && mv /tmp/oc.json ~/.config/opencode/oh-my-opencode.json
    echo "OpenCode notifications enabled ✓"
fi
```

#### For Claude Code

Add hooks to `~/.claude/settings.json`:

```bash
# Check if Claude Code settings exist
if [[ -f ~/.claude/settings.json ]]; then
    # Add hooks configuration
    # Note: This requires manual JSON editing or jq expertise
    echo "Add the following to ~/.claude/settings.json under 'hooks':"
    echo '
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.local/bin/notify-send '"'"'Claude Code'"'"' '"'"'Waiting for your input'"'"'",
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
            "command": "~/.local/bin/notify-send '"'"'Claude Code'"'"' '"'"'Task complete'"'"'",
            "async": true
          }
        ]
      }
    ]
  }
}'
fi
```

### Step 4: Verify Installation

```bash
# Test notification
~/.local/bin/notify --type=done "Test" "Installation verified"

# Test click-to-focus (minimize terminal first, then click notification)
```

## Hook Configuration Details

### Claude Code Hooks

| Hook | Trigger | Recommended Message |
|------|---------|---------------------|
| `Notification` | Waiting for user input | "Waiting for your input" |
| `Stop` | Agent finished responding | "Task complete" |

Full configuration example:
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

### OpenCode / oh-my-opencode

Simply add to config:
```json
{
  "notification": {
    "force_enable": true
  }
}
```

## Usage Examples

```bash
# Basic notification
notify "Title" "Message"

# With type (affects emoji)
notify --type=done "Complete" "Task finished"
notify --type=waiting "Input Needed" "Please confirm"
notify --type=error "Error" "Build failed"

# notify-send compatible (auto-detects type from content)
notify-send "Task complete" "3 files changed"
```

## Type Detection Keywords

| Type | Emoji | Keywords |
|------|-------|----------|
| done | ✅ | 完成, finished, complete, done, success, 成功 |
| waiting | ⏳ | 等待, waiting, input, confirm, 需要, waiting for |
| error | ❌ | 错误, error, fail, 失败, failed |
| warning | ⚠️ | warning, warn |
| info | 💡 | (default) |

## Troubleshooting

### Notification not showing

```bash
# Check if notify-send is in PATH
which notify-send

# Test PowerShell toast directly
powershell.exe -Command "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; Write-Host 'Toast API OK'"
```

### Click not focusing terminal

1. Verify registry was imported: Check `HKEY_CLASSES_ROOT\wslfocus` in regedit
2. Verify nircmd exists: `ls /mnt/c/Users/*/\.local/bin/nircmd.exe`

### Claude Code notifications not working

1. Check hooks configuration in `~/.claude/settings.json`
2. Verify notify-send path: `which notify-send`
3. Test manually: `~/.local/bin/notify-send "Test" "Message"`

### Chinese characters garbled

The scripts use base64 encoding. If issues persist:
```bash
# Test encoding
echo "测试" | base64 | base64 -d
```

## Files Installed

| Location | Purpose |
|----------|---------|
| `~/.local/bin/notify` | Main notification script |
| `~/.local/bin/notify-send` | Compatibility wrapper |
| `C:\Users\{user}\.local\bin\nircmd.exe` | Window focus tool |
| `C:\Users\{user}\.local\bin\focus-terminal.vbs` | Focus handler |
| `C:\Users\{user}\wsl-notify.reg` | Protocol registration |

## Uninstall

```bash
rm -f ~/.local/bin/notify ~/.local/bin/notify-send
# User must manually:
# - Delete registry key HKEY_CLASSES_ROOT\wslfocus
# - Delete C:\Users\{user}\.local\bin\nircmd.exe
# - Delete C:\Users\{user}\.local\bin\focus-terminal.vbs
```

## Quick Install Prompt for AI Agents

Copy this to any AI agent:

```
Install wsl-ai-notify for Windows notifications in WSL:

1. Run: curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/install.sh | bash
2. Ask user to double-click C:\Users\{username}\wsl-notify.reg

For OpenCode, add to ~/.config/opencode/oh-my-opencode.json:
{"notification": {"force_enable": true}}

For Claude Code, add hooks to ~/.claude/settings.json:
{"hooks": {"Notification": [{"hooks": [{"type": "command", "command": "~/.local/bin/notify-send 'Claude Code' 'Waiting for input'", "async": true}]}]}, "Stop": [{"hooks": [{"type": "command", "command": "~/.local/bin/notify-send 'Claude Code' 'Task complete'", "async": true}]}]}}
```
