# Agresywny test XDR – bardzo intensywna, ale BEZPIECZNA symulacja ransomware
Write-Host "[+] Aggressive Test – START"

$iterationsCrypto = 200
$iterationsFiles  = 5
$maxFiles         = 500

# --- 1. Intensywna kryptografia ---
for ($i = 0; $i -lt $iterationsCrypto; $i++) {
    $aes = [System.Security.Cryptography.Aes]::Create()
    $data = New-Object byte[] 2MB
    (New-Object System.Random).NextBytes($data)
    $enc = $aes.CreateEncryptor()
    $enc.TransformFinalBlock($data, 0, $data.Length) | Out-Null
}

Write-Host "[+] Kryptografia OK"

# --- 2. Masowe otwieranie plików ---
$files = Get-ChildItem $env:USERPROFILE -Recurse -ErrorAction SilentlyContinue |
         Where-Object { -not $_.PSIsContainer } |
         Select-Object -First $maxFiles

for ($j = 0; $j -lt $iterationsFiles; $j++) {
    foreach ($file in $files) {
        try {
            $s = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'Read')
            $s.Close()
        } catch {}
    }
    Write-Host "[+] Iteracja skanowania: $($j+1)"
}

Write-Host "[🔥] Aggressive Test – ZAKOŃCZONY"
