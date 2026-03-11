Write-Host "正在啟動 OpenClaw 平台..." -ForegroundColor Cyan
# 檢查 config
$configPath = "$PSScriptRoot\..\config\api_config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "錯誤: 找不到配置文件，請先執行 API 配置工具。" -ForegroundColor Red
    pause
    exit
}

$config = Get-Content $configPath | ConvertFrom-Json
Write-Host "目前模型來源: $($config.Provider)"

# 啟動邏輯 (範例)
if ($config.Provider -eq "Ollama (Local)") {
    Start-Process "ollama" -ArgumentList "serve"
    Start-Sleep -Seconds 5
    # 這裡應該執行主要的 python main.py
    Write-Host "OpenClaw (Ollama Mode) 正在啟動..."
} else {
    Write-Host "OpenClaw (Cloud API Mode) 正在啟動..."
}
