function Get-GPUInfo {

Write-Host "Detecting GPU..."

$gpu = Get-CimInstance Win32_VideoController

foreach ($g in $gpu) {

Write-Host "GPU Name:" $g.Name
Write-Host "VRAM:" ([math]::Round($g.AdapterRAM/1GB,2)) "GB"

}

}

function Test-CUDA {

Write-Host "Checking CUDA..."

$cuda = Get-Command nvidia-smi -ErrorAction SilentlyContinue

if($cuda){

Write-Host "CUDA environment detected"

nvidia-smi

}
else{

Write-Host "CUDA not detected"

}

}

Export-ModuleMember -Function Get-GPUInfo,Test-CUDA