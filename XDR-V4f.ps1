# =============================================================================
# XDR-Tester v5.1 (ENTERPRISE GRADE)
# Status: Production Ready / GC Safe / Context Aware
# Changes:
#   1. Garbage Collector Safety for Hooks (Global Delegate Ref)
#   2. Startup Admin Privileges Check
#   3. Full Error Handling & Logging
# =============================================================================

# Wymagane do GUI
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# -----------------------------------------------------------------------------
# 1. SILNIK WINAPI (HARDENED C#)
# -----------------------------------------------------------------------------
$cSharpCode = @"
using System;
using System.Runtime.InteropServices;

public class NativeSim {
    // --- HOOKING ---
    public delegate IntPtr HookProc(int code, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SetWindowsHookEx(int idHook, HookProc proc, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UnhookWindowsHookEx(IntPtr handle);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    // Callback przekazujący sterowanie dalej (nie blokuje inputu użytkownika)
    public static IntPtr SafeKeyCallback(int code, IntPtr wParam, IntPtr lParam) {
        return CallNextHookEx(IntPtr.Zero, code, wParam, lParam);
    }

    // --- PROCESS ACCESS ---
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
$global:StopRequested = $false
$global:UI = @{}

# [ENTERPRISE FIX 1] Zmienna globalna dla delegata, aby GC go nie usunął
$global:KeyboardHookDelegate = $null

function Write-Log {
    param(
        [string]$Message, 
        [ValidateSet("INFO","OK","WARN","FAIL","ALERT","TEST","ACT","ERR")]
        [string]$Type = "INFO"
    )
    try {
        $line = "{0} [{1}] {2}`r`n" -f (Get-Date -Format "HH:mm:ss"), $Type, $Message
        [System.IO.File]::AppendAllText($global:LogFile, $line)
    } catch {}
}

function DoEvents {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [System.Windows.Threading.DispatcherOperationCallback]{ param($f) $f.Continue = $false },
        $frame
    ) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Request-Stop { 
    $global:StopRequested = $true
    Write-Log "Użytkownik wymusił zatrzymanie." "WARN" 
}

function Check-Stop { 
    DoEvents
    if ($global:StopRequested) { throw [System.OperationCanceledException]::new("STOP") } 
}

function Reset-UI {
    $global:StopRequested = $false
    foreach ($key in @($global:UI.Keys)) {
        if ($key -like "PB_*") { $global:UI[$key].Value = 0 }
        elseif ($key -like "LBL_*") { $global:UI[$key].Text = "Oczekiwanie" }
    }
}

# -----------------------------------------------------------------------------
# [ENTERPRISE FIX 2] STARTUP ADMIN CHECK
# -----------------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    # Logujemy to od razu po starcie
    if (-not (Test-Path $global:LogFile)) { New-Item $global:LogFile -ItemType File -Force | Out-Null }
    Write-Log "Aplikacja uruchomiona bez uprawnień Administratora. Testy LSASS/Hook mogą nie zadziałać." "WARN"
} else {
    if (-not (Test-Path $global:LogFile)) { New-Item $global:LogFile -ItemType File -Force | Out-Null }
    Write-Log "Uprawnienia Administratora: TAK." "INFO"
}

# -----------------------------------------------------------------------------
# 3. MODUŁY TESTOWE
# -----------------------------------------------------------------------------

# --- RANSOMWARE ---
function Run-RansomSim {
    Reset-UI
    Write-Log "=== RANSOMWARE SIM START ===" "TEST"
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
            Write-Log "TIMEOUT: vssadmin zablokowany/zawieszony." "ALERT"
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
    Write-Log "=== LSASS DUMP SIM START ===" "TEST"
    $pb = $global:UI["PB_Lsass"]; $lbl = $global:UI["LBL_Lsass"]
    
    if (-not $isAdmin) { Write-Log "Brak Admina - dostęp do LSASS prawdopodobnie zostanie odrzucony przez system." "WARN" }

    $lsass = Get-Process -Name lsass -ErrorAction SilentlyContinue
    if (-not $lsass) { $lbl.Text = "Brak procesu"; return }
    
    $pb.Maximum = 5; $lbl.Text = "Atakowanie LSASS..."
    $accessFlags = 0x0010 -bor 0x0400 # VM_READ | QUERY_INFO
    
    try {
        for($i=0; $i -lt 5; $i++) {
            Check-Stop
            try {
                $h = [NativeSim]::OpenProcess($accessFlags, $false, $lsass.Id)
                if ($h -ne [IntPtr]::Zero) {
                    Write-Log "SUKCES: Otwarto uchwyt do LSASS! (Handle: $h)" "ALERT"
                    [NativeSim]::CloseHandle($h) | Out-Null
                } else {
                    $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                    Write-Log "BLOKADA: OpenProcess odmowa. Win32: $err" "BLOCK"
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
    Write-Log "=== PERSISTENCE SIM START ===" "TEST"
    $pb = $global:UI["PB_Persist"]; $lbl = $global:UI["LBL_Persist"]
    $pb.Maximum = 100; $lbl.Text = "Rejestr..."
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; $name = "XDR_Test_Key"
    
    try {
        Check-Stop
        New-ItemProperty -Path $regPath -Name $name -Value "calc.exe" -Force -ErrorAction Stop | Out-Null
        Write-Log "Klucz rejestru HKCU...Run utworzony." "ALERT"
        $pb.Value = 50; DoEvents; Start-Sleep -Milliseconds 500
        Remove-ItemProperty -Path $regPath -Name $name -ErrorAction SilentlyContinue | Out-Null
        Write-Log "Klucz usunięty." "INFO"
        $pb.Value = 100; $lbl.Text = "Zakończono"
    } catch { Write-Log ("Błąd Persistence: {0}" -f $_.Exception.Message) "FAIL" }
}

# --- NETWORK C2 ---
function Run-NetworkC2 {
    Reset-UI
    Write-Log "=== NETWORK C2 START ===" "TEST"
    $pb = $global:UI["PB_Net"]; $lbl = $global:UI["LBL_Net"]
    $doms = @("www.google.com", "www.bing.com", "github.com"); $pb.Maximum = $doms.Count
    
    $i=0
    foreach ($d in $doms) {
        Check-Stop; $i++
        try {
            Write-Log "GET https://$d/favicon.ico ..." "ACT"
            Invoke-WebRequest -Uri "https://$d/favicon.ico" -Method Get -TimeoutSec 3 | Out-Null
            Write-Log "Połączenie OK -> $d" "OK"
        } catch { Write-Log ("Blokada/Błąd -> $d : {0}" -f $_.Exception.Message) "FAIL" }
        $pb.Value = $i; DoEvents
    }
    $lbl.Text = "Zakończono"
}

# --- INJECTION / KEYLOG ---
function Run-Inject {
    Reset-UI
    Write-Log "=== INJECTION/HOOK SIM START ===" "TEST"
    $pb = $global:UI["PB_Inject"]; $lbl = $global:UI["LBL_Inject"]
    $procs = Get-Process | Select -First 5
    $pb.Maximum = 7
    
    $i=0
    foreach($p in $procs) {
        Check-Stop; $i++
        try {
            $h = [NativeSim]::OpenProcess([NativeSim]::PROCESS_QUERY_INFORMATION, $false, $p.Id)
            if ($h -ne [IntPtr]::Zero) { 
                Write-Log "Handle Open -> $($p.ProcessName)" "INFO"
                [NativeSim]::CloseHandle($h) | Out-Null
            }
        } catch {}
        $pb.Value = $i; DoEvents
    }

    # [ENTERPRISE FIX 1] GC Safety Implementation
    Check-Stop
    $lbl.Text = "Testowanie Hooka..."
    
    # Przypisujemy delegata do zmiennej globalnej!
    $global:KeyboardHookDelegate = [NativeSim+HookProc] { 
        param($c,$w,$l) 
        [NativeSim]::SafeKeyCallback($c,$w,$l) 
    }
    
    # Używamy zmiennej globalnej w wywołaniu
    $hHook = [NativeSim]::SetWindowsHookEx(13, $global:KeyboardHookDelegate, [IntPtr]::Zero, 0)
    
    if ($hHook -ne [IntPtr]::Zero) {
        Write-Log "SUKCES: Założono Global Keyboard Hook (WH_KEYBOARD_LL)!" "ALERT"
        $pb.Value = 6; DoEvents; Start-Sleep -Milliseconds 1000
        [NativeSim]::UnhookWindowsHookEx($hHook) | Out-Null
        Write-Log "Hook zdjęty." "INFO"
    } else {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Log "BLOKADA: SetWindowsHookEx nieudany. Win32: $err" "BLOCK"
    }
    
    # Czyścimy referencję po zakończeniu (opcjonalne, ale czyste)
    $global:KeyboardHookDelegate = $null
    
    $pb.Value = 7; $lbl.Text = "Zakończono"
}

# -----------------------------------------------------------------------------
# GUI CONSTRUCTION
# -----------------------------------------------------------------------------
$Window = New-Object System.Windows.Window
# Tytuł dostosowuje się do uprawnień
$Window.Title = if ($isAdmin) { "XDR-Tester v5.1 (ADMIN)" } else { "XDR-Tester v5.1 (USER MODE - Limited)" }
$Window.Width = 520; $Window.Height = 650
$Window.WindowStartupLocation = "CenterScreen"
$Window.Background = [System.Windows.Media.Brushes]::WhiteSmoke 

$Stack = New-Object System.Windows.Controls.StackPanel
$Stack.Margin = 10
$Window.Content = $Stack

$Title = New-Object System.Windows.Controls.TextBlock
$Title.Text = "XDR AUDIT TOOL v5.1"
$Title.FontSize = 18; $Title.FontWeight = "Bold"
$Title.HorizontalAlignment = "Center"; $Title.Margin = "0,0,0,15"
[void]$Stack.Children.Add($Title)

if (-not $isAdmin) {
    $Warn = New-Object System.Windows.Controls.TextBlock
    $Warn.Text = "⚠ BRAK UPRAWNIEŃ ADMINISTRATORA"
    $Warn.Foreground = [System.Windows.Media.Brushes]::Red
    $Warn.HorizontalAlignment = "Center"; $Warn.Margin = "0,0,0,10"
    [void]$Stack.Children.Add($Warn)
}

function Add-TestRow {
    param($Name,$Desc,$Func,$Key)
    $Border = New-Object System.Windows.Controls.Border; $Border.Margin = "0,0,0,8"; $Border.Padding = 5; $Border.Background = [System.Windows.Media.Brushes]::White; $Border.BorderBrush = [System.Windows.Media.Brushes]::LightGray; $Border.BorderThickness = 1
    $Grid = New-Object System.Windows.Controls.Grid; $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition)); $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
    
    $Btn = New-Object System.Windows.Controls.Button; $Btn.Content = "URUCHOM"; $Btn.Height = 35; $Btn.Add_Click($Func)
    [System.Windows.Controls.Grid]::SetColumn($Btn,0)
    
    $Panel = New-Object System.Windows.Controls.StackPanel; [System.Windows.Controls.Grid]::SetColumn($Panel,1); $Panel.Margin = "10,0,0,0"
    $LblTitle = New-Object System.Windows.Controls.TextBlock; $LblTitle.Text = $Name; $LblTitle.FontWeight = "Bold"
    $LblDesc = New-Object System.Windows.Controls.TextBlock; $LblDesc.Text = $Desc; $LblDesc.FontSize = 10; $LblDesc.Foreground = [System.Windows.Media.Brushes]::Gray
    $LblStatus = New-Object System.Windows.Controls.TextBlock; $LblStatus.Text = "Oczekiwanie"; $LblStatus.Foreground = [System.Windows.Media.Brushes]::DodgerBlue
    $PB = New-Object System.Windows.Controls.ProgressBar; $PB.Height = 8
    
    [void]$Panel.Children.Add($LblTitle); [void]$Panel.Children.Add($LblDesc); [void]$Panel.Children.Add($LblStatus); [void]$Panel.Children.Add($PB)
    [void]$Grid.Children.Add($Btn); [void]$Grid.Children.Add($Panel)
    $Border.Child = $Grid; [void]$Stack.Children.Add($Border)
    $global:UI["PB_$Key"] = $PB; $global:UI["LBL_$Key"] = $LblStatus
}

Add-TestRow "Ransomware" "AES-256 + vssadmin (Async)" { Run-RansomSim } "Ransom"
Add-TestRow "LSASS Dump" "OpenProcess (VM_READ | QUERY)" { Run-LsassSim } "Lsass"
Add-TestRow "Persistence" "Registry Run Key Modification" { Run-Persistence } "Persist"
Add-TestRow "Network C2" "HTTPS GET /favicon.ico" { Run-NetworkC2 } "Net"
Add-TestRow "Inject/Hook" "Handle Enum + Global Hook (GC Safe)" { Run-Inject } "Inject"

$BtnStop = New-Object System.Windows.Controls.Button; $BtnStop.Content = "ZATRZYMAJ"; $BtnStop.Height = 30; $BtnStop.Margin = "0,10,0,0"; $BtnStop.Background = [System.Windows.Media.Brushes]::MistyRose; $BtnStop.Add_Click({ Request-Stop })
[void]$Stack.Children.Add($BtnStop)

$BtnLog = New-Object System.Windows.Controls.Button; $BtnLog.Content = "OTWÓRZ LOG"; $BtnLog.Height = 30; $BtnLog.Margin = "0,5,0,0"; $BtnLog.Add_Click({ Start-Process notepad.exe $global:LogFile })
[void]$Stack.Children.Add($BtnLog)

$Window.ShowDialog() | Out-Null