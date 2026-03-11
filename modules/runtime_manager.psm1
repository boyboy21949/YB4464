function Install-Runtime {

Write-Host "Installing Python"

winget install Python.Python.3.11 -e --silent

Write-Host "Installing NodeJS"

winget install OpenJS.NodeJS -e --silent

Write-Host "Installing Git"

winget install Git.Git -e --silent

}

function Install-Ollama {

Write-Host "Installing Ollama"

winget install Ollama.Ollama -e --silent

}

Export-ModuleMember -Function Install-Runtime,Install-Ollama