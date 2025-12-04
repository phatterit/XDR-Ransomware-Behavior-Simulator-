# Ransomware Simulation - Medium Intensity
# Safe: does NOT encrypt real files.

$path = "$env:TEMP\mitre_test_files"
New-Item -ItemType Directory -Path $path -Force | Out-Null

for ($i = 0; $i -lt 200; $i++) {
    $file = "$path\test_$i.txt"
    Set-Content -Path $file -Value "Test file content"
    
    $bytes = New-Object byte[] 2000000
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
}

Write-Output "Medium intensity ransomware simulation completed."
