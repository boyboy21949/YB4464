Stop-Process -Name ollama -ErrorAction SilentlyContinue

Stop-Process -Name python -ErrorAction SilentlyContinue

Write-Host "Platform stopped"