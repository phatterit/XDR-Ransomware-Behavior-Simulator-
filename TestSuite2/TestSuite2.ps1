# === GUI WINDOW ===

$Window = New-Object System.Windows.Window
$Window.Title = "MITRE Test Suite"
$Window.Width = 380
$Window.Height = 320
$Window.WindowStartupLocation = "CenterScreen"

# GRID STRUCTURE
$Grid = New-Object System.Windows.Controls.Grid

# Define 6 rows
for ($i = 0; $i -lt 6; $i++) {
    $row = New-Object System.Windows.Controls.RowDefinition
    $row.Height = "Auto"
    $Grid.RowDefinitions.Add($row)
}

# Add a row for progress bar (stretch)
$rowStretch = New-Object System.Windows.Controls.RowDefinition
$rowStretch.Height = "*"
$Grid.RowDefinitions.Add($rowStretch)

# BUTTONS

$btnBasic = New-Object System.Windows.Controls.Button
$btnBasic.Content = "Run Basic Test"
$btnBasic.Height = 40
$btnBasic.Margin = "20"
$Grid.Children.Add($btnBasic)
[System.Windows.Controls.Grid]::SetRow($btnBasic, 0)

$btnMedium = New-Object System.Windows.Controls.Button
$btnMedium.Content = "Run Medium Test"
$btnMedium.Height = 40
$btnMedium.Margin = "20"
$Grid.Children.Add($btnMedium)
[System.Windows.Controls.Grid]::SetRow($btnMedium, 1)

$btnHigh = New-Object System.Windows.Controls.Button
$btnHigh.Content = "Run High Test"
$btnHigh.Height = 40
$btnHigh.Margin = "20"
$Grid.Children.Add($btnHigh)
[System.Windows.Controls.Grid]::SetRow($btnHigh, 2)

$btnOpenLog = New-Object System.Windows.Controls.Button
$btnOpenLog.Content = "Open Log File"
$btnOpenLog.Height = 40
$btnOpenLog.Margin = "20"
$Grid.Children.Add($btnOpenLog)
[System.Windows.Controls.Grid]::SetRow($btnOpenLog, 3)

# PROGRESS BAR + LABEL

$ProgressBar = New-Object System.Windows.Controls.ProgressBar
$ProgressBar.Margin = "20,5,20,0"
$ProgressBar.Height = 25
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = 100
$Grid.Children.Add($ProgressBar)
[System.Windows.Controls.Grid]::SetRow($ProgressBar, 4)

$ProgressLabel = New-Object System.Windows.Controls.Label
$ProgressLabel.Margin = "20,0,20,10"
$ProgressLabel.HorizontalAlignment = "Center"
$ProgressLabel.FontSize = 16
$Grid.Children.Add($ProgressLabel)
[System.Windows.Controls.Grid]::SetRow($ProgressLabel, 5)

$Global:ProgressBar = $ProgressBar
$Global:ProgressLabel = $ProgressLabel

$Window.Content = $Grid

# === BUTTON ACTIONS ===

$btnBasic.Add_Click({
    Write-Log "[ACTION] Basic test triggered"
    Run-BasicTest
    [System.Windows.MessageBox]::Show("Basic Test Completed","Done")
})

$btnMedium.Add_Click({
    Write-Log "[ACTION] Medium test triggered"
    Run-MediumTest
    [System.Windows.MessageBox]::Show("Medium Test Completed","Done")
})

$btnHigh.Add_Click({
    Write-Log "[ACTION] High test triggered"
    Run-HighTest
    [System.Windows.MessageBox]::Show("High Test Completed","Done")
})

$btnOpenLog.Add_Click({
    Write-Log "[ACTION] Open log requested"
    notepad.exe $global:LogFile
})

$Window.ShowDialog() | Out-Null
