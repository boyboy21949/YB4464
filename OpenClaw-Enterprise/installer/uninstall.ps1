$Root = "F:\AI 測試用沙盤\OpenClaw-Instance"
Write-Host "正在停止服務..." -ForegroundColor Yellow
Stop-Process -Name "ollama" -ErrorAction SilentlyContinue
Stop-Process -Name "python" -ErrorAction SilentlyContinue

Write-Host "正在移除檔案..." -ForegroundColor Yellow
if (Test-Path $Root) {
    Remove-Item $Root -Recurse -Force
}

Write-Host "正在移除桌面捷徑..." -ForegroundColor Yellow
$Desktop = [Environment]::GetFolderPath("Desktop")
Remove-Item "$Desktop\啟動 OpenClaw.lnk" -ErrorAction SilentlyContinue
Remove-Item "$Desktop\OpenClaw API配置.lnk" -ErrorAction SilentlyContinue

Write-Host "卸載完成。" -ForegroundColor Green
