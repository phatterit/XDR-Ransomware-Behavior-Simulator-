# Ransomware Simulation - High Intensity (Safe)
# Performs heavy RAM crypto loops + rapid mass file access.

$path = "$env:TEMP\mitre_high_test"
New-Item -ItemType Directory -Path $path -Force | Out-Null

# Create many dummy files
for ($i = 0; $i -lt 500; $i++) {
    $file = "$path\file_$i.txt"
    Set-Content -Path $file -Value ("X" * 10000)  # 10 KB
}

# Heavy crypto loop
for ($c = 0; $c -lt 100; $c++) {
    $bytes = New-Object byte[] 10000000
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
}

# Fast file opening pattern
Get-ChildItem $path | ForEach-Object {
    Get-Content $_.FullName | Out-Null
}

Write-Output "High intensity ransomware-like behavior simulated."
