# Symulacje zachowania ransomware (bezpieczne) – Testy XDR/EDR

Ten projekt zawiera **3 poziomy bezpiecznych testów**, które pozwalają
zweryfikować skuteczność systemów XDR/EDR w wykrywaniu zachowań typowych
dla ransomware – bez ryzyka uszkodzenia danych.

## ✔ Skrypty NIE:
- nie szyfrują plików
- nie modyfikują danych użytkownika
- nie usuwają plików
- nie wprowadzają trwałych zmian w systemie

## Poziomy testów:
1. **Test-Low.ps1** – lekki test kryptograficzny (RAM)
2. **Test-Medium.ps1** – I/O + kryptografia + szybkie operacje
3. **Test-High.ps1** – agresywne wzorce charakterystyczne dla ransomware

## MITRE ATT&CK
Skrypty odwołują się do technik:
- T1059.001 – PowerShell Execution  
- T1083 – File Discovery  
- T1486 – Data Encrypted for Impact (symulacja)  
- T1490 – Inhibit System Recovery (podobieństwo behawioralne)  

## Użycie
Uruchom PowerShell jako administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Test-High.ps1
