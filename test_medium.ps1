# Średni test XDR – imitacja ransomware bezpieczna
Write-Host "[+] Medium Test – start"

# 1. Mocniejsze operacje AES
for ($i = 0; $i -lt 100; $i++) {
    $aes = [System.Security.Cryptography.Aes]::Create()
    $data = New-Object byte[] 1MB
    (New-Object System.Random).NextBytes($data)
    $enc = $aes.CreateEncryptor()
    $enc.TransformFinalBlock($data, 0, $data.Length) | Out-Null
}

Write-Host "[*] Kryptografia wykonana"

# 2. Szybsze skanowanie plików bez ich dotykania
$files = Get-ChildItem $env:USERPROFILE -Recurse -ErrorAction SilentlyContinue |
         Where-Object { -not $_.PSIsContainer } |
         Select-Object -First 200

foreach ($file in $files) {
    try {
        $s = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'Read')
        $s.Close()
    } catch {}
}

Write-Host "[+] Medium Test – koniec"
