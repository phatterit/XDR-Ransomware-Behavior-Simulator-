# Ransomware Simulation - Low Intensity Test
# Safe test – does NOT encrypt, NOT delete, NOT modify files.

$bytes = New-Object byte[] 5000000  # 5 MB in-memory buffer
for ($i = 0; $i -lt 50; $i++) {
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
}
Write-Output "Low intensity ransomware behavior simulation completed."
