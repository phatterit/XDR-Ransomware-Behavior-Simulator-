# Ransomware Simulation - Medium Intensity (with visible output)
# Safe: does NOT encrypt real files.

$logFile = "$env:TEMP\mitre_test_log.txt"
Add-Content $logFile "`n==== Test started: $(Get-Date) ===="

Write-Host "[INFO] Starting Medium-Intensity Test..." -ForegroundColor Cyan

$path = "$env:TEMP\mitre_test_files"
New-Item -ItemType Directory -Path $path -Force | Out-Null
Write-Host "[INFO] Test folder: $path"

Add-Content $logFile "[INFO] Created test file $i"

$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

for ($i = 0; $i -lt 200; $i++) {

    Write-Host "[*] Creating file $i / 200" -ForegroundColor Yellow

    $file = "$path\test_$i.txt"
    Set-Content -Path $file -Value "Test file content"

    Write-Host "    -> Generating random cryptographic data..." -ForegroundColor Gray

    $bytes = New-Object byte[] 2000000
    $rng.GetBytes($bytes)

    Write-Host "    -> Operation completed." -ForegroundColor Green
}


Write-Host "[DONE] Medium intensity ransomware simulation completed." -ForegroundColor Green
Add-Content $logFile "[INFO] Simulation done $i"
