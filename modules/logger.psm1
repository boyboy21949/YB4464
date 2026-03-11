function Write-Log {

param([string]$Message)

$time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$line = "$time $Message"

Write-Host $line

}

Export-ModuleMember -Function Write-Log