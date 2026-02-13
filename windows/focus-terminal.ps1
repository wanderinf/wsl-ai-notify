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

$proc = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { exit 1 }

$hWnd = $proc.MainWindowHandle
if ($hWnd -eq [IntPtr]::Zero) { exit 1 }

# 检查窗口状态
$isMinimized = [Win32]::IsIconic($hWnd)
$isMaximized = [Win32]::IsZoomed($hWnd)

if ($isMinimized) {
    # 最小化状态 -> 还原
    [Win32]::ShowWindow($hWnd, [Win32]::SW_RESTORE) | Out-Null
} else {
    # 非最小化 -> 先最小化再还原（触发任务栏效果）
    [Win32]::ShowWindow($hWnd, 6) | Out-Null  # SW_MINIMIZE
    Start-Sleep -Milliseconds 50
    [Win32]::ShowWindow($hWnd, [Win32]::SW_RESTORE) | Out-Null
}

# 激活窗口
[Win32]::SetForegroundWindow($hWnd) | Out-Null

# 如果原来是最大化的，恢复最大化
if ($isMaximized) {
    [Win32]::ShowWindow($hWnd, 3) | Out-Null  # SW_MAXIMIZE
}