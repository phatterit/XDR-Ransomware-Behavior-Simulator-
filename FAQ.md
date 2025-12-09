**✔ Jak powinien zachować się XDR podczas uruchamiania MITRE Test Suite?**

Prawidłowo skonfigurowany XDR powinien wykazać reakcje na trzech poziomach:

**1) Detekcje behawioralne (Behavioral Detection)**

XDR powinien zauważyć:

a) Nietypowe użycie AES / operacji kryptograficznych

W testach LOW+AES, MEDIUM i HIGH następują:
szybkie, powtarzalne wywołania AES
operacje TransformFinalBlock
generowanie dużej ilości entropii w pamięci

Typowe alerty XDR:

Suspicious Cryptographic Activity Detected
Unusual Encryption Functions Invoked
Potential Ransomware Behavior – High Entropy Memory Allocation

b) File Enumeration (MITRE T1083) — MEDIUM / HIGH

Testy enumerują:
Dokumenty
Obrazy
Pulpit
Pliki użytkownika

które są typowymi celem ransomware.

XDR powinien wykryć:

Unusual File Enumeration Activity
Potential Pre-Encryption Behavior
Suspicious process accessing multiple user files

c) Rapid Read-Only access do setek plików — HIGH test

Nawet odczyt w trybie READONLY jest anomalią, jeśli:
proces masowo otwiera pliki
robi to sekwencyjnie i szybko
wykonuje to narzędzie, które normalnie nie powinno mieć takiej aktywności
Ransomware-y (Conti, LockBit, BlackCat) robią identyczną rzecz.

XDR powinien pokazać:

Process performing high-volume file I/O
Potential ransomware precursor activity
Multiple file access events within short time window

**2) Reakcje ochronne (Protection Actions)**

W zależności od trybu/ustawień XDR, reakcje mogą być różne.
Tryb Passive (Audit) – często w laboratoriach

XDR powinien:

generować alerty
raportować zachowania
NIE blokować procesu

Test powinien przejść do końca.
Tryb Alert + Block (EDR policy: High)

W środowisku firmowym typowa reakcja to:

a) Zablokowanie procesu

Proces testowy może zostać zatrzymany w trakcie:
intensywnego AES
enumeracji plików
masowego odczytu

Alert:

Ransomware behavior blocked
Process terminated to prevent encryption

b) Zablokowanie operacji I/O (IO Guard / Tamper Protection)
XDR może uniemożliwić:
dalsze otwieranie plików
enumerację
dostęp do katalogów użytkownika

c) Quarantine

Niektóre XDR oznaczą EXE jako potencjalnie szkodliwe i wyizolują go.

**3) Telemetria (Logging, Timeline, Indicators)**

Prawidłowy XDR powinien w konsoli administracyjnej pokazać:
Proces
nazwa EXE (np. MITRE_TestSuite.exe)
ścieżka do katalogu TEMP
hash pliku
Uprawnienia i zachowania
użycie .NET crypto API (AesCryptoServiceProvider, AesManaged)
allocate → high entropy → final block transform
enumeracja plików użytkownika
IO bursts (kilkaset operacji read-only)
Korelacja MITRE ATT&CK

Typowe mapowania:

Zachowanie	MITRE ID
File Enumeration	T1083
Data Encryption Behavior	T1486
File Read Before Encrypt	T1486.001
Staging / Pre-encryption Activity	T1485 / T1490
Suspicious Crypto Loop	T1027
✔ Jak zachowanie XDR powinno wyglądać w praktyce? (Podsumowanie)
Test	Co powinno wykryć XDR?	Czy powinien blokować?
LOW	Lekka aktywność AES	NIE blokować
LOW + AES	Duża aktywność AES, spike CPU	zależy od polityki
MEDIUM	AES + file discovery + read-only I/O	może zareagować, powinien ostrzec
HIGH	ransomware-like behavior, high I/O	wysokie ryzyko BLOKU

**✔ Co zrobić, jeśli Twój XDR nie wykrywa niczego?**

Możliwe powody:
Tryb ustawiony na Audit only
XDR nie monitoruje użytkownika (np. brak licencji Advanced)
Wyjątki folderów (Documents/Pictures wyłączone z monitoringu)
Proces działa w zaufanym kontekście użytkownika
Brak polityk Behavioral AI
XDR ignoruje procesy w %TEMP%
