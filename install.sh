#!/bin/bash
#
# WSL AI Notify - 一键安装脚本
# 
# 功能：为 WSL 中的 AI CLI 工具提供 Windows 原生通知
# 支持：OpenCode, Claude Code, Cursor CLI, 等等
#
# 使用：
#   curl -fsSL https://raw.githubusercontent.com/wanderinf/wsl-ai-notify/main/install.sh | bash
#

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否在 WSL 中
check_wsl() {
    if [[ ! -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        log_error "此脚本仅支持 WSL2"
        exit 1
    fi
    log_ok "检测到 WSL2 环境"
}

# 获取 Windows 用户名
get_windows_user() {
    cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r'
}

# 安装 Linux 端脚本
install_linux_scripts() {
    log_info "安装 Linux 端脚本..."
    
    mkdir -p ~/.local/bin
    
    # 创建 notify 脚本
    cat << 'NOTIFY_EOF' > ~/.local/bin/notify
#!/bin/bash
# WSL AI Notify - 通知脚本
# 使用 base64 编码解决中文传递问题

# Default values
TYPE="info"
TITLE=""
MESSAGE=""

# Parse arguments
while [[ \$# -gt 0 ]]; do
    case \$1 in
        --type=*)
            TYPE="\${1#*=}"
            shift
            ;;
        --type)
            TYPE="\$2"
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            if [[ -z "\$TITLE" ]]; then
                TITLE="\$1"
            elif [[ -z "\$MESSAGE" ]]; then
                MESSAGE="\$1"
            fi
            shift
            ;;
    esac
done

# Get context
PROJECT=\$(basename "\$PWD" 2>/dev/null || echo "?")
TIMESTAMP=\$(date +%H:%M:%S)

# Determine emoji based on type
case \$TYPE in
    done|complete|finished|success)
        EMOJI="✅"
        ;;
    waiting|input|confirm|question)
        EMOJI="⏳"
        ;;
    error|fail|failed)
        EMOJI="❌"
        ;;
    warning|warn)
        EMOJI="⚠️"
        ;;
    info|*)
        EMOJI="💡"
        ;;
esac

# Build title and message
FULL_TITLE="\$EMOJI [\$PROJECT]"

if [[ -n "\$MESSAGE" ]]; then
    FULL_MESSAGE="\$MESSAGE"\$'\n'"\$TIMESTAMP"
else
    FULL_MESSAGE="\$TIMESTAMP"
fi

# Base64 encode to handle Chinese characters
TITLE_B64=\$(echo -n "\$FULL_TITLE" | base64)
MESSAGE_B64=\$(echo -n "\$FULL_MESSAGE" | base64)

# Protocol launch args
LAUNCH_ARGS="wslfocus://\${PROJECT}"

# Send notification
powershell.exe -NoProfile -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

\\\$titleBytes = [System.Convert]::FromBase64String('\$TITLE_B64')
\\\$title = [System.Text.Encoding]::UTF8.GetString(\\\$titleBytes)
\\\$msgBytes = [System.Convert]::FromBase64String('\$MESSAGE_B64')
\\\$msg = [System.Text.Encoding]::UTF8.GetString(\\\$msgBytes)

\\\$title = \\\$title -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
\\\$msg = \\\$msg -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'

\\\$template = '<toast duration=\"long\" activationType=\"protocol\" launch=\"\$LAUNCH_ARGS\"><visual><binding template=\"ToastText02\"><text id=\"1\">' + \\\$title + '</text><text id=\"2\">' + \\\$msg + '</text></binding></visual></toast>'

\\\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\\\$xml.LoadXml(\\\$template)
\\\$toast = New-Object Windows.UI.Notifications.ToastNotification \\\$xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('AI Notify').Show(\\\$toast)
" 2>/dev/null
NOTIFY_EOF
    
    # 创建 notify-send 脚本
    cat << 'NOTIFY_SEND_EOF' > ~/.local/bin/notify-send
#!/bin/bash
# notify-send wrapper for AI CLI tools
# 自动根据内容推断通知类型

TITLE="\${1:-AI Notify}"
MESSAGE="\${2:-}"

# 智能推断类型
infer_type() {
    local content="\$1"
    
    if echo "\$content" | grep -qiE "完成|finished|complete|done|success|成功"; then
        echo "done"
        return
    fi
    
    if echo "\$content" | grep -qiE "错误|error|fail|失败|failed"; then
        echo "error"
        return
    fi
    
    if echo "\$content" | grep -qiE "等待|waiting|input|confirm|需要|waiting for"; then
        echo "waiting"
        return
    fi
    
    echo "info"
}

if [[ -n "\$MESSAGE" ]]; then
    TYPE=\$(infer_type "\$TITLE \$MESSAGE")
else
    TYPE=\$(infer_type "\$TITLE")
fi

~/.local/bin/notify --type="\$TYPE" "\$TITLE" "\$MESSAGE"
NOTIFY_SEND_EOF
    
    chmod +x ~/.local/bin/notify ~/.local/bin/notify-send
    
    # 确保 PATH 包含 ~/.local/bin
    if [[ ":\$PATH:" != *":\$HOME/.local/bin:"* ]]; then
        echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> ~/.bashrc
        log_info "已将 ~/.local/bin 添加到 PATH"
    fi
    
    log_ok "Linux 端脚本安装完成"
}

# 安装 Windows 端工具
install_windows_tools() {
    log_info "安装 Windows 端工具..."
    
    local WIN_USER=\$(get_windows_user)
    local WIN_BIN="/mnt/c/Users/\$WIN_USER/.local/bin"
    
    mkdir -p "\$WIN_BIN"
    
    # 下载 nircmd
    if [[ ! -f "\$WIN_BIN/nircmd.exe" ]]; then
        log_info "下载 nircmd..."
        curl -sL "https://www.nirsoft.net/utils/nircmd-x64.zip" -o /tmp/nircmd.zip
        unzip -o /tmp/nircmd.zip -d /tmp/nircmd/
        cp /tmp/nircmd/nircmd.exe "\$WIN_BIN/"
        log_ok "nircmd 安装完成"
    else
        log_ok "nircmd 已存在"
    fi
    
    # 创建 PowerShell 脚本（保留窗口最大化状态）
    cat << 'PS_EOF' > "\$WIN_BIN/focus-terminal.ps1"
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
    }
"@

\$proc = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not \$proc) { exit 1 }

\$hWnd = \$proc.MainWindowHandle
if (\$hWnd -eq [IntPtr]::Zero) { exit 1 }

# 检查窗口状态
\$isMinimized = [Win32]::IsIconic(\$hWnd)
\$isMaximized = [Win32]::IsZoomed(\$hWnd)

if (\$isMinimized) {
    # 最小化状态 -> 还原
    [Win32]::ShowWindow(\$hWnd, [Win32]::SW_RESTORE) | Out-Null
} else {
    # 非最小化 -> 先最小化再还原（触发任务栏效果）
    [Win32]::ShowWindow(\$hWnd, 6) | Out-Null  # SW_MINIMIZE
    Start-Sleep -Milliseconds 50
    [Win32]::ShowWindow(\$hWnd, [Win32]::SW_RESTORE) | Out-Null
}

# 激活窗口
[Win32]::SetForegroundWindow(\$hWnd) | Out-Null

# 如果原来是最大化的，恢复最大化
if (\$isMaximized) {
    [Win32]::ShowWindow(\$hWnd, 3) | Out-Null  # SW_MAXIMIZE
}
PS_EOF

    # 创建 VBScript（调用 PowerShell）
    cat << 'VBS_EOF' > "\$WIN_BIN/focus-terminal.vbs"
Set objShell = CreateObject("WScript.Shell")
' 调用 PowerShell 脚本，保留窗口最大化状态
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\focus-terminal.ps1""", 0, False
VBS_EOF
    
    # 创建注册表文件
    cat << REG_EOF > "/mnt/c/Users/\$WIN_USER/wsl-notify.reg"
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\wslfocus]
@="URL:WSL Focus Protocol"
"URL Protocol"=""

[HKEY_CLASSES_ROOT\wslfocus\shell]

[HKEY_CLASSES_ROOT\wslfocus\shell\open]

[HKEY_CLASSES_ROOT\wslfocus\shell\open\command]
@="wscript.exe \"C:\\\\Users\\\\\$WIN_USER\\\\.local\\\\bin\\\\focus-terminal.vbs\""
REG_EOF
    
    log_ok "Windows 端工具安装完成"
    log_warn "请双击运行 C:\\Users\\\$WIN_USER\\wsl-notify.reg 导入注册表"
}

# 配置 AI CLI 工具
configure_cli_tools() {
    log_info "检查 AI CLI 工具配置..."
    
    # OpenCode / oh-my-opencode
    if [[ -f ~/.config/opencode/oh-my-opencode.json ]]; then
        log_info "检测到 oh-my-opencode，配置通知..."
        if command -v jq &>/dev/null; then
            # 添加 notification.force_enable
            jq '.notification.force_enable = true' ~/.config/opencode/oh-my-opencode.json > /tmp/oh-my-opencode.json
            mv /tmp/oh-my-opencode.json ~/.config/opencode/oh-my-opencode.json
            log_ok "oh-my-opencode 通知已启用"
        else
            log_warn "请手动在 ~/.config/opencode/oh-my-opencode.json 中添加: {\"notification\": {\"force_enable\": true}}"
        fi
    fi
    
    log_ok "CLI 工具配置检查完成"
}

# 测试通知
test_notification() {
    log_info "发送测试通知..."
    sleep 1
    ~/.local/bin/notify --type=done "安装完成！" "WSL AI Notify 已就绪"
}

# 主流程
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║       WSL AI Notify Installer         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    check_wsl
    install_linux_scripts
    install_windows_tools
    configure_cli_tools
    
    echo ""
    log_info "安装完成！后续步骤："
    echo ""
    echo "  1. 导入注册表（双击 C:\\Users\\{用户名}\\wsl-notify.reg）"
    echo "  2. 重启终端"
    echo "  3. 运行: notify '测试' '通知正常工作'"
    echo ""
    
    test_notification
    
    echo ""
    log_ok "全部完成！点击通知测试跳转功能。"
}

main "\$@"
