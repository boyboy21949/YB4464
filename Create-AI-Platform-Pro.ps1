# ============================================================
# AI LOCAL PLATFORM PRO - INSTALLER GENERATOR (企業級穩定版)
# ============================================================
$ErrorActionPreference = "Stop"
$BaseDir = "F:\AI 測試用沙盤"
$ProjectRoot = Join-Path $BaseDir "AI-Platform-Pro"

Write-Host ">>> 正在初始化企業級 AI 部署工程於: $ProjectRoot" -ForegroundColor Cyan

# 1. 建立核心目錄 [cite: 25, 26]
$Dirs = @("installer", "modules", "ai", "tools", "config", "logs", "rollback")
foreach ($d in $Dirs) {
    $Path = Join-Path $ProjectRoot $d
    if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

# ------------------------------------------------------------
# 2. 生產：核心路徑管理模組 (解決你提到的 cd ..\ 問題)
# ------------------------------------------------------------
$PathManager = @'
function Get-ProjectRoot {
    return Split-Path -Parent $PSScriptRoot
}
function Get-Path {
    param([string]$SubDir)
    return Join-Path (Get-ProjectRoot) $SubDir
}
Export-ModuleMember -Function Get-ProjectRoot, Get-Path
'@
Set-Content (Join-Path $ProjectRoot "modules\PathManager.psm1") $PathManager

# ------------------------------------------------------------
# 3. 生產：部署引擎 (核心任務調度器) 
# ------------------------------------------------------------
$Engine = @'
$global:InstallTasks = @()
function Add-Task {
    param([string]$Name, [scriptblock]$Action)
    $global:InstallTasks += [PSCustomObject]@{ Name = $Name; Action = $Action }
}
function Execute-Deploy {
    Write-Host "`n=== 開始企業級部署流程 ===" -ForegroundColor Yellow
    foreach ($Task in $global:InstallTasks) {
        Write-Host "[-] 執行中: $($Task.Name)... " -NoNewline
        try {
            & $Task.Action
            Write-Host "成功" -ForegroundColor Green
        } catch {
            Write-Host "失敗!" -ForegroundColor Red
            Write-Error "錯誤詳情: $($_.Exception.Message)"
            exit 1
        }
    }
}
Export-ModuleMember -Function Add-Task, Execute-Deploy
'@
Set-Content (Join-Path $ProjectRoot "modules\DeployEngine.psm1") $Engine

# ------------------------------------------------------------
# 4. 生產：主安裝腳本 (install.ps1) [cite: 15, 16]
# ------------------------------------------------------------
$MainInstall = @"
Import-Module "`$PSScriptRoot\..\modules\PathManager.psm1"
Import-Module "`$PSScriptRoot\..\modules\DeployEngine.psm1"

`$LogPath = Get-Path "logs\deploy.log"

Add-Task "系統衝突檢測" {
    if (Get-Process "ollama" -ErrorAction SilentlyContinue) {
        Write-Warning "檢測到 Ollama 正在運行，安裝後可能需要重啟。"
    }
}

Add-Task "安裝 Python 3.11 環境" {
    winget install Python.Python.3.11 -e --silent --accept-package-agreements
}

Add-Task "部署 Ollama 與模型 (Llama3)" {
    winget install Ollama.Ollama -e --silent
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -s 5
    & ollama pull llama3
}

Add-Task "建立桌面快捷方式" {
    `$WshShell = New-Object -ComObject WScript.Shell
    `$Shortcut = `$WshShell.CreateShortcut("`$env:USERPROFILE\Desktop\啟動AI平台.lnk")
    `$Shortcut.TargetPath = "powershell.exe"
    `$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `$(Get-Path 'tools\start.ps1')"
    `$Shortcut.Save()
}

Execute-Deploy
"@
Set-Content (Join-Path $ProjectRoot "installer\install.ps1") $MainInstall

# ------------------------------------------------------------
# 5. 生產：啟動工具 (start.ps1) [cite: 41]
# ------------------------------------------------------------
$StartScript = @"
Write-Host ">>> 正在啟動本地 AI 服務..." -ForegroundColor Cyan
Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
Start-Sleep -s 2
Write-Host ">>> 服務已就緒。您可以開始使用 Llama3 了。" -ForegroundColor Green
pause
"@
Set-Content (Join-Path $ProjectRoot "tools\start.ps1") $StartScript

Write-Host "`n[完成] 工程已生產完畢！" -ForegroundColor Green
Write-Host "請進入目錄: $ProjectRoot\installer"
Write-Host "執行: .\install.ps1 開始正式部署。"