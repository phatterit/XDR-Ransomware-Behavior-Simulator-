# Ransomware Simulation - High Intensity (WinPS compatible)

$path = "$env:TEMP\mitre_high_test"
New-Item -ItemType Directory -Path $path -Force | Out-Null

# Generate dummy files
for ($i = 0; $i -lt 500; $i++) {
    $file = "$path\file_$i.txt"
    Set-Content -Path $file -Value ("X" * 10000)
}

# Heavy crypto work
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

for ($c = 0; $c -lt 100; $c++) {
    $bytes = New-Object byte[] 10000000
    $rng.GetBytes($bytes)
}

# Rapid file access
Get-ChildItem $path | ForEach-Object {
    Get-Content $_.FullName | Out-Null
}

Write-Output "High intensity ransomware-like behavior simulated."
