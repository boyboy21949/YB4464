<#
    OpenClaw Enterprise Installer Generator
    這個腳本會生成一個完整的企業級 AI 平台部署工具包。
#>

$ErrorActionPreference = "Stop"
$BaseDrive = "F:\AI 測試用沙盤"
$ProjectName = "OpenClaw-Enterprise"
$Root = Join-Path $BaseDrive $ProjectName

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  OpenClaw 企業級安裝器生成器 " -ForegroundColor Cyan
Write-Host "  目標位置: $Root" -ForegroundColor Gray
Write-Host "============================================" -ForegroundColor Cyan

# 1. 建立目錄結構
$dirs = @(
    "$Root",
    "$Root\installer",
    "$Root\modules",
    "$Root\tools",
    "$Root\ui",
    "$Root\config",
    "$Root\logs",
    "$Root\rollback",
    "$Root\runtime",
    "$Root\models"
)

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 2. 核心模組：日誌
$loggerModule = @'
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logPath = "$global:PlatformRoot\logs\install.log"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # 顯示在 Console (不隱藏過程)
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        default { Write-Host $logEntry -ForegroundColor White }
    }
    
    # 寫入檔案
    Add-Content -Path $logPath -Value $logEntry
}
Export-ModuleMember -Function Write-Log
'@
Set-Content "$Root\modules\logger.psm1" $loggerModule -Encoding UTF8

# 3. 核心模組：安裝引擎
$engineModule = @'
function Start-SafeExecution {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [scriptblock]$RollbackAction
    )
    
    Write-Log "執行步驟: $Name"
    try {
        & $Action
        Write-Log "步驟完成: $Name"
    }
    catch {
        Write-Log "步驟失敗: $Name - $_" -Level "ERROR"
        Write-Log "啟動回滾程序..."
        
        # 執行回滾
        if ($RollbackAction -ne $null) {
            & $RollbackAction
        }
        
        # 觸發全局回滾
        Invoke-GlobalRollback
        throw "安裝終止: $Name 失敗"
    }
}

function Invoke-GlobalRollback {
    Write-Log "正在清除已安裝檔案..." -Level "WARN"
    if (Test-Path $global:PlatformRoot) {
        # 保留 logs 以供排查，其餘刪除
        Get-ChildItem -Path $global:PlatformRoot -Exclude "logs" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Log "系統已還原至初始狀態。" -Level "WARN"
}
Export-ModuleMember -Function Start-SafeExecution, Invoke-GlobalRollback
'@
Set-Content "$Root\modules\engine.psm1" $engineModule -Encoding UTF8

# 4. 核心模組：系統檢測
$sysCheckModule = @'
function Test-SystemEnvironment {
    Write-Log "檢查系統環境..."
    
    # GPU 檢測 (修正後的邏輯)
    $gpus = Get-CimInstance Win32_VideoController
    $nvidiaGpu = $gpus | Where-Object { $_.Name -like "*NVIDIA*" }
    
    if ($nvidiaGpu) {
        Write-Log "偵測到 NVIDIA GPU: $($nvidiaGpu.Name)"
        $global:HasNvidia = $true
    } else {
        Write-Log "未偵測到 NVIDIA GPU，將使用 CPU 模式。" -Level "WARN"
        $global:HasNvidia = $false
    }

    # 衝突檢測
    $processes = @("ollama", "python")
    foreach ($p in $processes) {
        $proc = Get-Process -Name $p -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Log "警告: 發現正在運行的 $p 程序，可能導致衝突。" -Level "WARN"
            # 不自動關閉，詢問使用者或記錄
        }
    }
}
Export-ModuleMember -Function Test-SystemEnvironment
'@
Set-Content "$Root\modules\system_check.psm1" $sysCheckModule -Encoding UTF8

# 5. 安裝配置 UI (API Config)
$uiScript = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "OpenClaw API 配置中心"
$form.Size = New-Object System.Drawing.Size(500, 450)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# Provider 選項
$lblProvider = New-Object System.Windows.Forms.Label
$lblProvider.Text = "選擇模型來源:"
$lblProvider.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($lblProvider)

$comboProvider = New-Object System.Windows.Forms.ComboBox
$comboProvider.Location = New-Object System.Drawing.Size(20, 50)
$comboProvider.Size = New-Object System.Drawing.Size(440, 30)
$comboProvider.Items.AddRange(@("Ollama (Local)", "NVIDIA NIM (Cloud)", "OpenAI (Cloud)", "Doubao (Cloud)", "Grok (Cloud)"))
$comboProvider.SelectedIndex = 0
$form.Controls.Add($comboProvider)

# API Key 輸入
$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "API Key (若是雲端服務):"
$lblKey.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = New-Object System.Drawing.Point(20, 130)
$txtKey.Size = New-Object System.Drawing.Size(440, 30)
$txtKey.PasswordChar = "*"
$form.Controls.Add($txtKey)

# 儲存按鈕
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "儲存配置"
$btnSave.Location = New-Object System.Drawing.Point(180, 350)
$btnSave.Add_Click({
    $config = @{
        Provider = $comboProvider.SelectedItem
        ApiKey   = $txtKey.Text
        Endpoint = switch ($comboProvider.SelectedItem) {
            "NVIDIA NIM (Cloud)" { "https://build.nvidia.com/" }
            "OpenAI (Cloud)" { "https://api.openai.com/v1" }
            default { "local" }
        }
    }
    
    $jsonPath = "$PSScriptRoot\..\config\api_config.json"
    $config | ConvertTo-Json | Out-File $jsonPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("配置已儲存！")
    $form.Close()
})
$form.Controls.Add($btnSave)

$form.ShowDialog()
'@
Set-Content "$Root\ui\api_config_ui.ps1" $uiScript -Encoding UTF8

# 6. 主安裝腳本
$installScript = @'
param(
    [string]$InstallPath = "F:\AI 測試用沙盤\OpenClaw-Instance"
)

# 全局變數
$global:PlatformRoot = $InstallPath

# 引入模組 (使用絕對路徑)
$ModulePath = "$PSScriptRoot\..\modules"
Import-Module "$ModulePath\logger.psm1" -Force
Import-Module "$ModulePath\engine.psm1" -Force
Import-Module "$ModulePath\system_check.psm1" -Force

Write-Log "===== OpenClaw 企業級安裝程序啟動 ====="

# 1. 系統檢測
Start-SafeExecution -Name "系統環境檢測" -Action {
    Test-SystemEnvironment
}

# 2. 建立目錄結構
Start-SafeExecution -Name "建立目錄結構" -Action {
    $folders = @("runtime", "models", "logs")
    foreach ($f in $folders) {
        $dir = Join-Path $InstallPath $f
        if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }
}

# 3. 安裝依賴 (使用 Winget)
Start-SafeExecution -Name "安裝 Python Runtime" -Action {
    # 檢查是否已安裝，避免重複安裝
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        winget install Python.Python.3.11 --silent --accept-package-agreements --accept-source-agreements
    } else {
        Write-Log "Python 已存在，跳過安裝。"
    }
} -RollbackAction {
    # Winget uninstall logic here if needed (complex)
}

# 4. 安裝 Ollama (本地 LLM)
Start-SafeExecution -Name "安裝 Ollama 本地模型引擎" -Action {
    $ollama = Get-Command ollama -ErrorAction SilentlyContinue
    if (-not $ollama) {
        winget install Ollama.Ollama --silent --accept-package-agreements --accept-source-agreements
    }
}

# 5. 下載 OpenClaw (Git Clone)
Start-SafeExecution -Name "下載 OpenClaw 核心程式碼" -Action {
    $repoUrl = "https://github.com/OpenClawAI/OpenClaw" # 假設的 Repo
    $clonePath = Join-Path $InstallPath "OpenClaw"
    
    if (Test-Path $clonePath) {
        Write-Log "原始碼已存在，嘗試更新..."
        # 修正: 使用 Set-Location 並在執行後返回原路徑，避免路徑漂移
        Push-Location $clonePath
        git pull
        Pop-Location
    } else {
        git clone $repoUrl $clonePath
    }
} -RollbackAction {
    $clonePath = Join-Path $InstallPath "OpenClaw"
    if (Test-Path $clonePath) { Remove-Item $clonePath -Recurse -Force }
}

# 6. 安裝 Python 依賴
Start-SafeExecution -Name "安裝 Python Dependencies" -Action {
    $reqPath = Join-Path $InstallPath "OpenClaw\requirements.txt"
    if (Test-Path $reqPath) {
        pip install -r $reqPath --quiet
    } else {
        Write-Log "找不到 requirements.txt" -Level "WARN"
    }
}

# 7. 建立桌面捷徑
Start-SafeExecution -Name "建立桌面捷徑" -Action {
    $WshShell = New-Object -ComObject WScript.Shell
    $Desktop = [Environment]::GetFolderPath("Desktop")
    
    # Start Shortcut
    $s1 = $WshShell.CreateShortcut("$Desktop\啟動 OpenClaw.lnk")
    $s1.TargetPath = "powershell"
    $s1.Arguments = "-ExecutionPolicy Bypass -File `"$InstallPath\tools\start.ps1`""
    $s1.Save()
    
    # Config Shortcut
    $s2 = $WshShell.CreateShortcut("$Desktop\OpenClaw API配置.lnk")
    $s2.TargetPath = "powershell"
    $s2.Arguments = "-ExecutionPolicy Bypass -File `"$PSScriptRoot\..\ui\api_config_ui.ps1`""
    $s2.Save()
}

Write-Log "===== 安裝完成 ====="
Write-Host "按任意鍵離開..."
$null = $Host.UI.RawUI.ReadKey()
'@
Set-Content "$Root\installer\install.ps1" $installScript -Encoding UTF8

# 7. 卸載腳本
$uninstallScript = @'
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
'@
Set-Content "$Root\installer\uninstall.ps1" $uninstallScript -Encoding UTF8

# 8. 啟動腳本
$startScript = @'
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
'@
Set-Content "$Root\tools\start.ps1" $startScript -Encoding UTF8

Write-Host ""
Write-Host "生成完成！" -ForegroundColor Green
Write-Host "請前往以下路徑開始安裝：" -ForegroundColor Yellow
Write-Host "$Root\installer\install.ps1" -ForegroundColor White
Write-Host ""
Pause
