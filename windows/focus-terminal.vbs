Set objShell = CreateObject("WScript.Shell")
' 调用 PowerShell 脚本，保留窗口最大化状态
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\focus-terminal.ps1""", 0, False
