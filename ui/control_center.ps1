Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text="AI Local Platform"
$form.Width=500
$form.Height=400

$startBtn = New-Object Windows.Forms.Button
$startBtn.Text="Start Platform"
$startBtn.Width=150
$startBtn.Top=30
$startBtn.Left=30

$stopBtn = New-Object Windows.Forms.Button
$stopBtn.Text="Stop Platform"
$stopBtn.Width=150
$stopBtn.Top=80
$stopBtn.Left=30

$modelBtn = New-Object Windows.Forms.Button
$modelBtn.Text="Model Manager"
$modelBtn.Width=150
$modelBtn.Top=130
$modelBtn.Left=30

$apiBtn = New-Object Windows.Forms.Button
$apiBtn.Text="API Config"
$apiBtn.Width=150
$apiBtn.Top=180
$apiBtn.Left=30

$monitorBtn = New-Object Windows.Forms.Button
$monitorBtn.Text="System Monitor"
$monitorBtn.Width=150
$monitorBtn.Top=230
$monitorBtn.Left=30

$startBtn.Add_Click({
powershell ..\tools\start_platform.ps1
})

$stopBtn.Add_Click({
powershell ..\tools\stop_platform.ps1
})

$modelBtn.Add_Click({
powershell ..\tools\model_manager.ps1
})

$apiBtn.Add_Click({
powershell ..\ui\api_config_ui.ps1
})

$form.Controls.AddRange(@($startBtn,$stopBtn,$modelBtn,$apiBtn,$monitorBtn))

$form.ShowDialog()