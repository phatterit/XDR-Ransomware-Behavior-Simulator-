# Ransomware Simulation - Medium Intensity (WinPS compatible)

$path = "$env:TEMP\mitre_test_files"
New-Item -ItemType Directory -Path $path -Force | Out-Null

$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

for ($i = 0; $i -lt 200; $i++) {
    $file = "$path\test_$i.txt"
    Set-Content -Path $file -Value "Test file content"

    $bytes = New-Object byte[] 2000000
    $rng.GetBytes($bytes)
}

Write-Output "Medium intensity ransomware simulation completed."
