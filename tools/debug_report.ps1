$path="..\logs"

$zip="..\AI_debug_$(Get-Date -Format yyyyMMdd).zip"

Compress-Archive $path $zip

Write-Host "Debug report created:"
Write-Host $zip