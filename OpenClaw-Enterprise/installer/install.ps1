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
