function Get-APIConfig {

$config = Get-Content "..\config\api.json" | ConvertFrom-Json

return $config

}

function Invoke-LLM {

param($prompt)

$config = Get-APIConfig

switch($config.provider){

"ollama" {

ollama run llama3 $prompt

}

"default" {

Write-Host "No provider configured"

}

}

}

Export-ModuleMember -Function Invoke-LLM