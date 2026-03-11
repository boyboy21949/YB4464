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
