Write-Host ""
Write-Host "Model Manager"
Write-Host ""

Write-Host "1 Download model"
Write-Host "2 Remove model"
Write-Host "3 List models"

$choice = Read-Host "Select"

switch($choice){

1 {

$name = Read-Host "Model name"

ollama pull $name

}

2 {

$name = Read-Host "Model name"

ollama rm $name

}

3 {

ollama list

}

}