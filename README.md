# XDR Ransomware Behavior Simulator (Safe)

Ten projekt zawiera **BEZPIECZNE** skrypty PowerShell symulujące zachowania typowe dla ransomware.  
ŻADEN skrypt nie szyfruje, nie modyfikuje ani nie usuwa plików – działają tylko w pamięci,  
powodując charakterystyczne wzorce I/O oraz kryptografii, które powinny być wykrywane przez XDR/EDR.

Skrypty są przeznaczone do:
- testowania systemów XDR/EDR
- edukacji w zakresie cyberbezpieczeństwa
- badań red-team / blue-team
- laboratoriów ofensywnych i defensywnych

## ⚠️ OSTRZEŻENIE
Te skrypty **NIE są malware**, jednak imitują ich zachowanie.  
Używaj ich **WYŁĄCZNIE** na własnym komputerze lub w środowisku testowym/labowym.  
Autor nie ponosi odpowiedzialności za niewłaściwe użycie.

---

## 📂 Zawartość

### 1️⃣ `test_light.ps1`
Lekka symulacja — minimalne zachowania podejrzane  
Powinno wywołać alert typu:  
**"Suspicious PowerShell Crypto Activity"**

### 2️⃣ `test_medium.ps1`
Średnia symulacja — umiarkowane I/O + operacje AES  
Alerty takie jak:  
**"Potential Ransomware Behavior"**

### 3️⃣ `test_aggressive.ps1`
Agresywna symulacja — intensywna kryptografia i masowe otwieranie plików  
Alerty XDR zazwyczaj:  
**"Ransomware-like Activity Detected"**  
**"Mass File Access"**

---

## ▶️ Jak uruchomić?

Otwórz PowerShell (Run as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\tests\test_light.ps1
.\tests\test_medium.ps1
.\tests\test_aggressive.ps1
```

---

## 📜 Licencja
MIT — możesz używać, modyfikować i udostępniać.

