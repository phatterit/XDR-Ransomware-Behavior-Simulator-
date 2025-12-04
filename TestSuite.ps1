Add-Type -AssemblyName PresentationFramework

# === LOG SETUP ===
$global:LogFile = "$env:TEMP\MITRE_Test_Log.txt"
function Write-Log {
    param([string]$msg)
    Add-Content $global:LogFile "$(Get-Date -Format 'HH:mm:ss')  $msg"
}

# === TEST FUNCTIONS ===

function Run-BasicTest {
    Write-Log "==== Basic Test Started ===="

    try {
        $path = "$env:TEMP\basic_test_file.txt"
        Set-Content $path "Basic test content"
        Write-Log "[INFO] Created basic test file: $path"

        Start-Sleep -Seconds 1
        Write-Log "[INFO] Basic test completed successfully."
    }
    catch {
        Write-Log "[ERROR] Basic test failed: $_"
    }

    Write-Log "==== Basic Test Ended ===="
}

function Run-MediumTest {
    Write-Log "==== Medium Test Started ===="

    try {
        $folder = "$env:TEMP\MediumTest"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Log "[INFO] Created folder: $folder"

        for ($i = 1; $i -le 100; $i++) {
            $f = "$folder\file_$i.txt"
            Set-Content $f "Medium test file $i"
            Write-Log "[INFO] Created file: file_$i.txt"
        }

        Start-Sleep -Seconds 1
        Write-Log "[INFO] Medium test completed."
    }
    catch {
        Write-Log "[ERROR] Medium test failed: $_"
    }

    Write-Log "==== Medium Test Ended ===="
}

function Run-HighTest {
    Write-Log "==== High Test Started ===="

    try {
        $folder = "$env:TEMP\HighTest"
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Log "[INFO] Created high test folder: $folder"

        for ($i = 1; $i -le 300; $i++) {
            $f = "$folder\high_$i.txt"
            Set-Content $f ("HIGH TEST FILE #$i")
            Write-Log "[INFO] Created high test file high_$i.txt"
        }

        # Simulate “heavier” behavior flagged by XDR
        Write-Log "[INFO] Starting heavy CPU cycle simulation..."
        for ($i = 1; $i -le 200000; $i++) { $null = [math]::Sqrt($i) }
        Write-Log "[INFO] CPU simulation complete."

        Write-Log "[INFO] High test completed."
    }
    catch {
        Write-Log "[ERROR] High test failed: $_"
    }

    Write-Log "==== High Test Ended ===="
}

# === GUI WINDOW ===

$Window = New-Object System.Windows.Window
$Window.Title = "MITRE Test Suite"
$Window.Width = 350
$Window.Height = 260
$Window.WindowStartupLocation = "CenterScreen"

$Grid = New-Object System.Windows.Controls.Grid
$Window.Content = $Grid

# Buttons
$btnBasic = New-Object System.Windows.Controls.Button
$btnBasic.Content = "Run Basic Test"
$btnBasic.Margin = "20,20,20,0"
$btnBasic.Height = 40

$btnMedium = New-Object System.Windows.Controls.Button
$btnMedium.Content = "Run Medium Test"
$btnMedium.Margin = "20,70,20,0"
$btnMedium.Height = 40

$btnHigh = New-Object System.Windows.Controls.Button
$btnHigh.Content = "Run High Test"
$btnHigh.Margin = "20,120,20,0"
$btnHigh.Height = 40

$btnOpenLog = New-Object System.Windows.Controls.Button
$btnOpenLog.Content = "Open Log File"
$btnOpenLog.Margin = "20,170,20,0"
$btnOpenLog.Height = 40


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


$Grid.Children.Add($btnBasic)
$Grid.Children.Add($btnMedium)
$Grid.Children.Add($btnHigh)
$Grid.Children.Add($btnOpenLog)

$Window.ShowDialog() | Out-Null
