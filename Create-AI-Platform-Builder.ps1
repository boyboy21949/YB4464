# ==========================================
# AI LOCAL PLATFORM BUILDER GENERATOR
# Enterprise Modular Installer Generator
# ==========================================

$BasePath = "F:\AI 測試用沙盤"
$Project = "AI-Platform-Builder"
$Root = Join-Path $BasePath $Project

Write-Host ""
Write-Host "======================================"
Write-Host "AI Platform Builder Generator"
Write-Host "======================================"
Write-Host ""

# ----------------------------------
# Create Directory Structure
# ----------------------------------

$dirs = @(
"$Root",
"$Root\installer",
"$Root\modules",
"$Root\ai",
"$Root\runtime",
"$Root\models",
"$Root\tools",
"$Root\ui",
"$Root\config",
"$Root\logs",
"$Root\packages"
)

foreach ($d in $dirs) {

    if (!(Test-Path $d)) {

        New-Item -ItemType Directory -Path $d | Out-Null

    }

}

Write-Host "Directory structure created"

# ----------------------------------
# Logger Module
# ----------------------------------

$logger = @'
function Write-Log {

param([string]$msg)

$log="$global:InstallPath\logs\install.log"

$time=Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$line="$time : $msg"

Write-Host $line

Add-Content $log $line

}

Export-ModuleMember -Function Write-Log
'@

Set-Content "$Root\modules\logger.psm1" $logger

# ----------------------------------
# Rollback Module
# ----------------------------------

$rollback = @'
function Start-Rollback {

Write-Host "Rollback starting..."

if(Test-Path $global:InstallPath){

Remove-Item $global:InstallPath -Recurse -Force

}

Write-Host "Rollback finished"

}

Export-ModuleMember -Function Start-Rollback
'@

Set-Content "$Root\modules\rollback.psm1" $rollback

# ----------------------------------
# System Check Module
# ----------------------------------

$systemCheck = @'
function Test-System {

Write-Host "Checking system requirements..."

$python = Get-Command python -ErrorAction SilentlyContinue
$node = Get-Command node -ErrorAction SilentlyContinue
$git = Get-Command git -ErrorAction SilentlyContinue

if(!$python){ Write-Host "Python not detected" }
if(!$node){ Write-Host "NodeJS not detected" }
if(!$git){ Write-Host "Git not detected" }

$gpu = Get-CimInstance Win32_VideoController

Write-Host "GPU:"
$gpu.Name

}

Export-ModuleMember -Function Test-System
'@

Set-Content "$Root\modules\system_check.psm1" $systemCheck

# ----------------------------------
# Network Check Module
# ----------------------------------

$networkCheck = @'
function Test-Network {

Write-Host "Testing internet connection..."

try{

Invoke-WebRequest "https://github.com" -UseBasicParsing | Out-Null

Write-Host "Internet OK"

}
catch{

Write-Host "Internet connection failed"

}

}

Export-ModuleMember -Function Test-Network
'@

Set-Content "$Root\modules\network_check.psm1" $networkCheck

# ----------------------------------
# Downloader Module
# ----------------------------------

$downloader = @'
function Download-GitRepo {

param($repo,$path)

Write-Host "Cloning repository $repo"

git clone $repo $path

}

function Download-File {

param($url,$dest)

Invoke-WebRequest $url -OutFile $dest

}

Export-ModuleMember -Function Download-GitRepo,Download-File
'@

Set-Content "$Root\modules\downloader.psm1" $downloader

# ----------------------------------
# Shortcut Module
# ----------------------------------

$shortcut = @'
function Create-Shortcut {

param($name,$script)

$desktop="$env:USERPROFILE\Desktop"

$WshShell = New-Object -ComObject WScript.Shell

$s=$WshShell.CreateShortcut("$desktop\$name.lnk")

$s.TargetPath="powershell"

$s.Arguments="-ExecutionPolicy Bypass -File $script"

$s.Save()

}

Export-ModuleMember -Function Create-Shortcut
'@

Set-Content "$Root\modules\shortcut.psm1" $shortcut

# ----------------------------------
# Install Script
# ----------------------------------

$installScript = @'
param(

[string]$InstallPath="F:\AI 測試用沙盤\AI-Local-Platform"

)

$global:InstallPath=$InstallPath

Import-Module "..\modules\logger.psm1"
Import-Module "..\modules\rollback.psm1"
Import-Module "..\modules\system_check.psm1"
Import-Module "..\modules\network_check.psm1"
Import-Module "..\modules\downloader.psm1"
Import-Module "..\modules\shortcut.psm1"

Write-Log "Installer started"

Test-System
Test-Network

New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallPath\logs" | Out-Null

Write-Log "Installing Python"

winget install Python.Python.3.11 -e --silent

Write-Log "Installing NodeJS"

winget install OpenJS.NodeJS -e --silent

Write-Log "Installing Ollama"

winget install Ollama.Ollama -e --silent

Write-Log "Downloading OpenClaw"

Download-GitRepo "https://github.com/OpenClawAI/OpenClaw" "$InstallPath\OpenClaw"

Write-Log "Installation completed"

Create-Shortcut "Start AI Platform" "$InstallPath\tools\start_platform.ps1"

'@

Set-Content "$Root\installer\install.ps1" $installScript

# ----------------------------------
# Platform start tool
# ----------------------------------

$startTool = @'
Write-Host "Starting AI Platform..."

cd "F:\AI 測試用沙盤\AI-Local-Platform\OpenClaw"

python main.py
'@

Set-Content "$Root\tools\start_platform.ps1" $startTool

# ----------------------------------
# API Config
# ----------------------------------

$api = @'
{
"provider":"ollama",
"ollama_url":"http://localhost:11434",
"openai_key":"",
"grok_key":"",
"nvidia_url":"https://build.nvidia.com",
"doubao_key":""
}
'@

Set-Content "$Root\config\api.json" $api

Write-Host ""
Write-Host "AI Platform Builder created successfully"
Write-Host ""
Write-Host "Location:"
Write-Host $Root
Write-Host ""