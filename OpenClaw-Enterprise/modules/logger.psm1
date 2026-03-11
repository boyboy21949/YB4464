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
