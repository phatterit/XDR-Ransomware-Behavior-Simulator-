# Lekki test XDR – bezpieczna symulacja ransomware
Write-Host "[+] Light Test – start"

# Inicjalizacja AES (imitacja kryptografii)
for ($i = 0; $i -lt 20; $i++) {
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key | Out-Null
    $aes.IV  | Out-Null
}

# Losowe operacje w pamięci (bez modyfikacji plików)
for ($i = 0; $i -lt 20; $i++) {
    $data = New-Object byte[] 512KB
    (New-Object System.Random).NextBytes($data)
}

Write-Host "[+] Light Test – koniec"
