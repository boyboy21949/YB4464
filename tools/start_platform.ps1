Write-Host "Starting AI Platform..."

Start-Process ollama

Start-Sleep 3

powershell ..\ui\control_center.ps1