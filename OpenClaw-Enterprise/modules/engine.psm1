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
