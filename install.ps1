Import-Module "..\modules\gpu_detect.psm1"
Import-Module "..\modules\runtime_manager.psm1"

Write-Log "Detect GPU"

Get-GPUInfo
Test-CUDA

Write-Log "Install Runtime"

Install-Runtime

Write-Log "Install Ollama"

Install-Ollama

Write-Log "Install Agents"

powershell "..\ai\agents_install.ps1"

Write-Log "Install Diffusion"

powershell "..\ai\diffusion_install.ps1"

Write-Log "Download Models"

powershell "..\ai\ollama_models.ps1"

Import-Module ..\modules\installer_engine.psm1
Import-Module ..\modules\runtime_manager.psm1

Add-InstallTask "Create Platform Folder" {

New-Item -ItemType Directory -Force "F:\AI 測試用沙盤\AI-Platform"

}

Add-InstallTask "Install Runtime" {

Install-Runtime

}

Add-InstallTask "Install Ollama" {

powershell ..\ai\ollama_install.ps1

}

Add-InstallTask "Install AI Agents" {

powershell ..\ai\agents_install.ps1

}

Add-InstallTask "Install Stable Diffusion" {

powershell ..\ai\diffusion_install.ps1

}

Add-InstallTask "Create Tools Folder" {

New-Item -ItemType Directory -Force "F:\AI 測試用沙盤\AI-Platform\tools"

}

Start-Installer