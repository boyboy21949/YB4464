while($true){

Clear-Host

Write-Host "AI Platform Monitor"

Get-Process | Where-Object { $_.CPU -ne $null } | Sort-Object CPU -Descending | Select-Object -First 10

$nvidia = Get-Command nvidia-smi -ErrorAction SilentlyContinue

if($nvidia){

nvidia-smi

}

Start-Sleep 5

}