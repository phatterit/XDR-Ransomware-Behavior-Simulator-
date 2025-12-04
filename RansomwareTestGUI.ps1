Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- OKNO ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ransomware Simulation Launcher"
$form.Size = New-Object System.Drawing.Size(400,250)
$form.StartPosition = "CenterScreen"

# --- PRZYCISKI ---
$btnLow = New-Object System.Windows.Forms.Button
$btnLow.Text = "Run LOW test"
$btnLow.Width = 300
$btnLow.Height = 40
$btnLow.Location = New-Object System.Drawing.Point(50,20)
$form.Controls.Add($btnLow)

$btnMed = New-Object System.Windows.Forms.Button
$btnMed.Text = "Run MEDIUM test"
$btnMed.Width = 300
$btnMed.Height = 40
$btnMed.Location = New-Object System.Drawing.Point(50,80)
$form.Controls.Add($btnMed)

$btnHigh = New-Object System.Windows.Forms.Button
$btnHigh.Text = "Run HIGH test"
$btnHigh.Width = 300
$btnHigh.Height = 40
$btnHigh.Location = New-Object System.Drawing.Point(50,140)
$form.Controls.Add($btnHigh)

# --- FUNKCJA URUCHAMIAJĄCA ---
function Run-Test($file) {
    if (-Not (Test-Path $file)) {
        [System.Windows.Forms.MessageBox]::Show("Brak skryptu: $file")
        return
    }
    powershell -NoProfile -ExecutionPolicy Bypass -File $file
}

# --- AKCJE ---
$btnLow.Add_Click({ Run-Test "Test-Low.ps1" })
$btnMed.Add_Click({ Run-Test "Test-Medium.ps1" })
$btnHigh.Add_Click({ Run-Test "Test-High.ps1" })

# --- START ---
$form.ShowDialog()
