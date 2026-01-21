# =============================================================================
# XDR-Tester v5.2 (REPORTING EDITION)
# Status: Production Ready / HTML Reporting Added
# =============================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# -----------------------------------------------------------------------------
# 1. SILNIK WINAPI (HARDENED C#)
# -----------------------------------------------------------------------------
$cSharpCode = @"
using System;
using System.Runtime.InteropServices;

public class NativeSim {
    public delegate IntPtr HookProc(int code, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SetWindowsHookEx(int idHook, HookProc proc, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UnhookWindowsHookEx(IntPtr handle);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    public static IntPtr SafeKeyCallback(int code, IntPtr wParam, IntPtr lParam) {
        return CallNextHookEx(IntPtr.Zero, code, wParam, lParam);
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public const int PROCESS_VM_READ = 0x0010;
    public const int PROCESS_QUERY_INFORMATION = 0x0400; 
}
"@

try {
    Add-Type -TypeDefinition $cSharpCode -Language CSharp -ErrorAction Stop
}
catch {
    [System.Windows.MessageBox]::Show("Krytyczny błąd kompilacji WinAPI: $($_.Exception.Message)", "FATAL ERROR")
    exit 1
}

# -----------------------------------------------------------------------------
# 2. KONFIGURACJA I LOGOWANIE
# -----------------------------------------------------------------------------
$global:LogFile = "$env:TEMP\XDR_Tester_Log.txt"
$global:ReportFile = "$env:TEMP\XDR_Report.html"
$global:StopRequested = $false
$global:UI = @{}
$global:KeyboardHookDelegate = $null

# Inicjalizacja czystego logu
if (Test-Path $global:LogFile) { Clear-Content $global:LogFile }

function Write-Log {
    param(
        [string]$Message, 
        [ValidateSet("INFO","OK","WARN","FAIL","ALERT","TEST","ACT","ERR","BLOCK")]
        [string]$Type = "INFO"
    )
    try {
        $line = "{0}|{1}|{2}`r`n" -f (Get-Date -Format "HH:mm:ss"), $Type, $Message
        [System.IO.File]::AppendAllText($global:LogFile, $line)
    } catch {}
}

function DoEvents {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false }, $frame) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Request-Stop { $global:StopRequested = $true; Write-Log "Użytkownik wymusił zatrzymanie." "WARN" }
function Check-Stop { DoEvents; if ($global:StopRequested) { throw [System.OperationCanceledException]::new("STOP") } }

function Reset-UI {
    $global:StopRequested = $false
    foreach ($key in @($global:UI.Keys)) {
        if ($key -like "PB_*") { $global:UI[$key].Value = 0 }
        elseif ($key -like "LBL_*") { $global:UI[$key].Text = "Oczekiwanie" }
    }
}

# -----------------------------------------------------------------------------
# 3. SILNIK RAPORTOWANIA HTML (NOWOŚĆ)
# -----------------------------------------------------------------------------
function Generate-HtmlReport {
    if (-not (Test-Path $global:LogFile)) { [System.Windows.MessageBox]::Show("Brak logów do analizy."); return }
    
    $logs = Get-Content $global:LogFile
    $rows = ""
    $blockedCount = 0
    $alertCount = 0
    $totalTests = 0

    foreach ($line in $logs) {
        if ($line -match "(.*)\|(.*)\|(.*)") {
            $time = $matches[1]
            $type = $matches[2]
            $msg  = $matches[3]
            
            # Kolorowanie wierszy
            $rowClass = ""
            $badgeClass = "badge-info"
            
            switch ($type) {
                "TEST"  { $rowClass = "row-test"; $badgeClass="badge-test"; $totalTests++ }
                "ALERT" { $rowClass = "row-danger"; $badgeClass="badge-danger"; $alertCount++ } # Atak udany (Źle dla XDR)
                "BLOCK" { $rowClass = "row-success"; $badgeClass="badge-success"; $blockedCount++ } # Atak zablokowany (Dobrze dla XDR)
                "FAIL"  { $rowClass = "row-success"; $badgeClass="badge-success"; $blockedCount++ } # Fail ataku to często sukces ochrony
                "ACT"   { $rowClass = ""; $badgeClass="badge-act" }
                "ERR"   { $rowClass = "row-warning"; $badgeClass="badge-warning" }
            }

            $rows += "<tr class='$rowClass'><td>$time</td><td><span class='badge $badgeClass'>$type</span></td><td>$msg</td></tr>"
        }
    }

    # Szablon HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f9; color: #333; margin: 0; padding: 20px; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); border-radius: 8px; }
    h1 { text-align: center; color: #2c3e50; }
    .summary { display: flex; justify-content: space-around; margin-bottom: 20px; padding: 15px; background: #ecf0f1; border-radius: 5px; }
    .score-card { text-align: center; }
    .score-val { font-size: 24px; font-weight: bold; }
    .val-red { color: #e74c3c; } .val-green { color: #27ae60; } .val-blue { color: #2980b9; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; }
    th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background-color: #34495e; color: white; }
    tr:hover { background-color: #f1f1f1; }
    
    .row-test { background-color: #e8f6f3; font-weight: bold; border-top: 2px solid #aaa; }
    .row-danger { background-color: #fadbd8; } /* Atak udany */
    .row-success { background-color: #d4efdf; } /* Blokada XDR */
    .row-warning { background-color: #fdebd0; }

    .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; color: white; font-weight: bold; }
    .badge-test { background-color: #1abc9c; }
    .badge-danger { background-color: #e74c3c; }
    .badge-success { background-color: #27ae60; }
    .badge-info { background-color: #95a5a6; }
    .badge-act { background-color: #3498db; }
    .badge-warning { background-color: #f39c12; }
</style>
</head>
<body>
<div class="container">
    <h1>XDR Audit Report</h1>
    <div class="summary">
        <div class="score-card"><div class="score-val val-blue">$totalTests</div><div>Scenariusze</div></div>
        <div class="score-card"><div class="score-val val-green">$blockedCount</div><div>Zablokowane (Secure)</div></div>
        <div class="score-card"><div class="score-val val-red">$alertCount</div><div>Przepuszczone (Risk)</div></div>
    </div>
    <p><strong>Host:</strong> $env:COMPUTERNAME | <strong>User:</strong> $env:USERNAME | <strong>Date:</strong> $(Get-Date)</p>
    <table>
        <thead><tr><th width="15%">Czas</th><th width="10%">Typ</th><th>Zdarzenie</th></tr></thead>
        <tbody>
            $rows
        </tbody>
    </table>
</div>
</body>
</html>
"@
    
    $html | Out-File $global:ReportFile -Encoding UTF8
    Start-Process $global:ReportFile
}

# -----------------------------------------------------------------------------
# 4. STARTUP CHECK
# -----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Log "Aplikacja uruchomiona bez uprawnień Administratora." "WARN" } else { Write-Log "Uprawnienia Administratora: TAK." "INFO" }

# -----------------------------------------------------------------------------
# 5. MODUŁY TESTOWE
# -----------------------------------------------------------------------------

# --- RANSOMWARE ---
function Run-RansomSim {
    Reset-UI
    Write-Log "Ransomware Simulation (AES + VSS)" "TEST"
    $pb = $global:UI["PB_Ransom"]; $lbl = $global:UI["LBL_Ransom"]
    $pb.Maximum = 20; $lbl.Text = "Szyfrowanie..."

    try {
        for ($i = 1; $i -le 20; $i++) {
            Check-Stop
            try {
                $aes = [System.Security.Cryptography.Aes]::Create()
                $aes.KeySize = 256; $aes.GenerateKey(); $aes.GenerateIV()
                $buf = New-Object byte[] 65536
                (New-Object Random).NextBytes($buf)
                $null = $aes.CreateEncryptor().TransformFinalBlock($buf, 0, $buf.Length)
            } catch { Write-Log ("Błąd krypto: {0}" -f $_.Exception.Message) "ERR" }
            $pb.Value = $i; DoEvents
        }
        
        $lbl.Text = "VSSAdmin..."
        Write-Log "Uruchamianie vssadmin list shadows..." "ACT"
        $p = Start-Process "vssadmin.exe" -ArgumentList "List Shadows" -NoNewWindow -PassThru
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not $p.HasExited -and $sw.ElapsedMilliseconds -lt 5000) { DoEvents; Start-Sleep -Milliseconds 100 }
        
        if (-not $p.HasExited) {
            Write-Log "TIMEOUT: vssadmin zablokowany/zawieszony przez XDR." "BLOCK"
            try { $p.Kill() } catch {}
        } else {
            Write-Log "vssadmin zakończony. ExitCode: $($p.ExitCode)" "OK"
        }
        $lbl.Text = "Zakończono"
    } catch { $lbl.Text = "Błąd"; Write-Log $_.Exception.Message "FAIL" }
}

# --- LSASS DUMP ---
function Run-LsassSim {
    Reset-UI
    Write-Log "Credential Access (LSASS Dump)" "TEST"
    $pb = $global:UI["PB_Lsass"]; $lbl = $global:UI["LBL_Lsass"]
    
    $lsass = Get-Process -Name lsass -ErrorAction SilentlyContinue
    if (-not $lsass) { $lbl.Text = "Brak procesu"; Write-Log "Brak dostępu do procesu LSASS (wymagany Admin)." "INFO"; return }
    
    $pb.Maximum = 5; $lbl.Text = "Atakowanie LSASS..."
    $accessFlags = 0x0010 -bor 0x0400 
    
    try {
        for($i=0; $i -lt 5; $i++) {
            Check-Stop
            try {
                $h = [NativeSim]::OpenProcess($accessFlags, $false, $lsass.Id)
                if ($h -ne [IntPtr]::Zero) {
                    Write-Log "SUKCES: Otwarto uchwyt do LSASS! (Zagrożenie)" "ALERT"
                    [NativeSim]::CloseHandle($h) | Out-Null
                } else {
                    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                    Write-Log "BLOKADA: Odmowa dostępu do LSASS (Win32: $err)" "BLOCK"
                }
            } catch {}
            $pb.Value = $i+1; DoEvents; Start-Sleep -Milliseconds 250
        }
        $lbl.Text = "Zakończono"
    } catch {}
}

# --- PERSISTENCE ---
function Run-Persistence {
    Reset-UI
    Write-Log "Persistence (Registry Run Key)" "TEST"
    $pb = $global:UI["PB_Persist"]; $lbl = $global:UI["LBL_Persist"]
    $pb.Maximum = 100; $lbl.Text = "Rejestr..."
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; $name = "XDR_Test_Key"
    
    try {
        Check-Stop
        New-ItemProperty -Path $regPath -Name $name -Value "calc.exe" -Force -ErrorAction Stop | Out-Null
        Write-Log "Klucz rejestru utworzony pomyślnie (Zagrożenie)." "ALERT"
        $pb.Value = 50; DoEvents; Start-Sleep -Milliseconds 500
        Remove-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue | Out-Null
        Write-Log "Klucz usunięty." "INFO"
        $pb.Value = 100; $lbl.Text = "Zakończono"
    } catch { Write-Log ("Rejestr zablokowany: {0}" -f $_.Exception.Message) "BLOCK" }
}

# --- NETWORK C2 ---
function Run-NetworkC2 {
    Reset-UI
    Write-Log "Network C2 (HTTPS Beacon)" "TEST"
    $pb = $global:UI["PB_Net"]; $lbl = $global:UI["LBL_Net"]
    $doms = @("www.google.com", "www.bing.com", "github.com"); $pb.Maximum = $doms.Count
    
    $i=0
    foreach ($d in $doms) {
        Check-Stop; $i++
        try {
            Write-Log "GET https://$d/favicon.ico ..." "ACT"
            Invoke-WebRequest -Uri "https://$d/favicon.ico" -Method Get -TimeoutSec 3 | Out-Null
            Write-Log "Połączenie nawiązane (Ruch przepuszczony)." "OK"
        } catch { Write-Log ("Połączenie zablokowane: {0}" -f $_.Exception.Message) "BLOCK" }
        $pb.Value = $i; DoEvents
    }
    $lbl.Text = "Zakończono"
}

# --- INJECTION ---
function Run-Inject {
    Reset-UI
    Write-Log "Process Injection & Hooking" "TEST"
    $pb = $global:UI["PB_Inject"]; $lbl = $global:UI["LBL_Inject"]
    $procs = Get-Process | Select -First 5
    $pb.Maximum = 7
    
    $i=0
    foreach($p in $procs) {
        Check-Stop; $i++
        try {
            $h = [NativeSim]::OpenProcess([NativeSim]::PROCESS_QUERY_INFORMATION, $false, $p.Id)
            if ($h -ne [IntPtr]::Zero) { 
                Write-Log "Handle Open -> $($p.ProcessName) (Success)" "ALERT"
                [NativeSim]::CloseHandle($h) | Out-Null
            }
        } catch {}
        $pb.Value = $i; DoEvents
    }

    Check-Stop; $lbl.Text = "Keylogger Hook..."
    $global:KeyboardHookDelegate = [NativeSim+HookProc] { param($c,$w,$l) [NativeSim]::SafeKeyCallback($c,$w,$l) }
    $hHook = [NativeSim]::SetWindowsHookEx(13, $global:KeyboardHookDelegate, [IntPtr]::Zero, 0)
    
    if ($hHook -ne [IntPtr]::Zero) {
        Write-Log "Keylogger Hook założony pomyślnie (Zagrożenie)!" "ALERT"
        $pb.Value = 6; DoEvents; Start-Sleep -Milliseconds 1000
        [NativeSim]::UnhookWindowsHookEx($hHook) | Out-Null
    } else {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Log "Keylogger zablokowany. Win32: $err" "BLOCK"
    }
    $global:KeyboardHookDelegate = $null
    $pb.Value = 7; $lbl.Text = "Zakończono"
}

# -----------------------------------------------------------------------------
# GUI
# -----------------------------------------------------------------------------
$Window = New-Object System.Windows.Window
$Window.Title = if ($isAdmin) { "XDR-Tester v5.2 (ADMIN)" } else { "XDR-Tester v5.2 (USER MODE)" }
$Window.Width = 520; $Window.Height = 680; $Window.WindowStartupLocation = "CenterScreen"; $Window.Background = [System.Windows.Media.Brushes]::WhiteSmoke 

$Stack = New-Object System.Windows.Controls.StackPanel; $Stack.Margin = 10; $Window.Content = $Stack

$Title = New-Object System.Windows.Controls.TextBlock
$Title.Text = "XDR AUDIT TOOL v5.2"; $Title.FontSize = 18; $Title.FontWeight = "Bold"; $Title.HorizontalAlignment = "Center"; $Title.Margin = "0,0,0,15"
[void]$Stack.Children.Add($Title)

if (-not $isAdmin) {
    $Warn = New-Object System.Windows.Controls.TextBlock; $Warn.Text = "⚠ BRAK UPRAWNIEŃ ADMINA"; $Warn.Foreground = [System.Windows.Media.Brushes]::Red; $Warn.HorizontalAlignment = "Center"; $Warn.Margin = "0,0,0,10"
    [void]$Stack.Children.Add($Warn)
}

function Add-TestRow {
    param($Name,$Desc,$Func,$Key)
    $Border = New-Object System.Windows.Controls.Border; $Border.Margin="0,0,0,8"; $Border.Padding=5; $Border.Background=[System.Windows.Media.Brushes]::White; $Border.BorderBrush=[System.Windows.Media.Brushes]::LightGray; $Border.BorderThickness=1
    $Grid = New-Object System.Windows.Controls.Grid; $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition)); $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
    
    $Btn = New-Object System.Windows.Controls.Button; $Btn.Content="URUCHOM"; $Btn.Height=35; $Btn.Add_Click($Func)
    [System.Windows.Controls.Grid]::SetColumn($Btn,0)
    
    $Panel = New-Object System.Windows.Controls.StackPanel; [System.Windows.Controls.Grid]::SetColumn($Panel,1); $Panel.Margin="10,0,0,0"
    $L1=New-Object System.Windows.Controls.TextBlock; $L1.Text=$Name; $L1.FontWeight="Bold"
    $L2=New-Object System.Windows.Controls.TextBlock; $L2.Text=$Desc; $L2.FontSize=10; $L2.Foreground=[System.Windows.Media.Brushes]::Gray
    $L3=New-Object System.Windows.Controls.TextBlock; $L3.Text="Oczekiwanie"; $L3.Foreground=[System.Windows.Media.Brushes]::DodgerBlue
    $PB=New-Object System.Windows.Controls.ProgressBar; $PB.Height=8
    
    [void]$Panel.Children.Add($L1); [void]$Panel.Children.Add($L2); [void]$Panel.Children.Add($L3); [void]$Panel.Children.Add($PB)
    [void]$Grid.Children.Add($Btn); [void]$Grid.Children.Add($Panel)
    $Border.Child=$Grid; [void]$Stack.Children.Add($Border)
    $global:UI["PB_$Key"]=$PB; $global:UI["LBL_$Key"]=$L3
}

Add-TestRow "Ransomware" "AES-256 + vssadmin (Async)" { Run-RansomSim } "Ransom"
Add-TestRow "LSASS Dump" "OpenProcess (VM_READ)" { Run-LsassSim } "Lsass"
Add-TestRow "Persistence" "Registry Run Key Modification" { Run-Persistence } "Persist"
Add-TestRow "Network C2" "HTTPS GET /favicon.ico" { Run-NetworkC2 } "Net"
Add-TestRow "Inject/Hook" "Handle Enum + Global Hook" { Run-Inject } "Inject"

$BtnReport = New-Object System.Windows.Controls.Button
$BtnReport.Content = "GENERUJ RAPORT HTML"
$BtnReport.Height = 40; $BtnReport.Margin = "0,15,0,0"; $BtnReport.Background = [System.Windows.Media.Brushes]::CornflowerBlue; $BtnReport.Foreground = [System.Windows.Media.Brushes]::White; $BtnReport.FontWeight = "Bold"
$BtnReport.Add_Click({ Generate-HtmlReport })
[void]$Stack.Children.Add($BtnReport)

$BtnLog = New-Object System.Windows.Controls.Button
$BtnLog.Content = "PODGLĄD SUROWEGO LOGU"; $BtnLog.Height = 30; $BtnLog.Margin = "0,5,0,0"
$BtnLog.Add_Click({ Start-Process notepad.exe $global:LogFile })
[void]$Stack.Children.Add($BtnLog)

$Window.ShowDialog() | Out-Null