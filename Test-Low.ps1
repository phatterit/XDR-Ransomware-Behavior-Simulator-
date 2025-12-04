# Ransomware Simulation - Low Intensity Test (WinPS compatible)

$bytes = New-Object byte[] 5000000
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

for ($i = 0; $i -lt 50; $i++) {
    $rng.GetBytes($bytes)
}

Write-Output "Low intensity ransomware behavior simulation completed."
