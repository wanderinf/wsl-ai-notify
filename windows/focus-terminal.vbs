Set objShell = CreateObject("WScript.Shell")
objShell.Run "nircmd.exe win activate process ""WindowsTerminal.exe""", 0, False
