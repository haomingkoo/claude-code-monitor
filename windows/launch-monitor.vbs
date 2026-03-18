Set objShell = CreateObject("WScript.Shell")
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
objShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\claude-code-monitor.ps1""", 0, False
