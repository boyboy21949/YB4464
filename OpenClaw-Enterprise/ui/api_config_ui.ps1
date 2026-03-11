Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "OpenClaw API 配置中心"
$form.Size = New-Object System.Drawing.Size(500, 450)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# Provider 選項
$lblProvider = New-Object System.Windows.Forms.Label
$lblProvider.Text = "選擇模型來源:"
$lblProvider.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($lblProvider)

$comboProvider = New-Object System.Windows.Forms.ComboBox
$comboProvider.Location = New-Object System.Drawing.Size(20, 50)
$comboProvider.Size = New-Object System.Drawing.Size(440, 30)
$comboProvider.Items.AddRange(@("Ollama (Local)", "NVIDIA NIM (Cloud)", "OpenAI (Cloud)", "Doubao (Cloud)", "Grok (Cloud)"))
$comboProvider.SelectedIndex = 0
$form.Controls.Add($comboProvider)

# API Key 輸入
$lblKey = New-Object System.Windows.Forms.Label
$lblKey.Text = "API Key (若是雲端服務):"
$lblKey.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($lblKey)

$txtKey = New-Object System.Windows.Forms.TextBox
$txtKey.Location = New-Object System.Drawing.Point(20, 130)
$txtKey.Size = New-Object System.Drawing.Size(440, 30)
$txtKey.PasswordChar = "*"
$form.Controls.Add($txtKey)

# 儲存按鈕
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "儲存配置"
$btnSave.Location = New-Object System.Drawing.Point(180, 350)
$btnSave.Add_Click({
    $config = @{
        Provider = $comboProvider.SelectedItem
        ApiKey   = $txtKey.Text
        Endpoint = switch ($comboProvider.SelectedItem) {
            "NVIDIA NIM (Cloud)" { "https://build.nvidia.com/" }
            "OpenAI (Cloud)" { "https://api.openai.com/v1" }
            default { "local" }
        }
    }
    
    $jsonPath = "$PSScriptRoot\..\config\api_config.json"
    $config | ConvertTo-Json | Out-File $jsonPath -Encoding UTF8
    [System.Windows.Forms.MessageBox]::Show("配置已儲存！")
    $form.Close()
})
$form.Controls.Add($btnSave)

$form.ShowDialog()
