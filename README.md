# # # XDR Diagnostic Tool

**Enterprise-grade narzędzie do audytu XDR / EDR**  
*Bezpieczna symulacja ataków • MITRE ATT&CK • Raportowanie HTML*

---

## 📌 Opis projektu

**XDR Diagnostic Tool** to **produkcyjne narzędzie audytowe** przeznaczone do oceny skuteczności systemów **XDR / EDR** na stacjach roboczych z systemem Windows.

Projekt koncentruje się na **kontrolowanej symulacji zachowań atakujących**, generując **rzeczywistą telemetrię bezpieczeństwa**, bez wykorzystywania podatności, bez destrukcji danych i bez przechwytywania poufnych informacji.

Celem narzędzia jest odpowiedź na kluczowe pytanie:

> **Czy wdrożona ochrona endpointów faktycznie wykrywa i blokuje realne techniki ataku?**

---

## 🎯 Założenia projektowe

- bezpieczne użycie w środowisku produkcyjnym  
- testy oparte o **zachowanie**, a nie sygnatury  
- brak dumpów pamięci i kradzieży danych  
- jednoznaczne rozróżnienie: **zablokowane vs przepuszczone**  
- czytelne raporty dla zespołów SOC / Blue / Purple  

---

## 🧠 Koncepcja działania

- symulacja **rzeczywistych technik ataku**, nie malware  
- użycie **WinAPI poprzez zahartowany kod C#**  
- każde zdarzenie klasyfikowane jako:
  - **ALERT** – atak zakończył się powodzeniem (ryzyko)
  - **BLOCK / FAIL** – mechanizmy ochrony zadziałały poprawnie  
- automatyczne generowanie **raportu HTML**

---

## 🧩 Zaimplementowane techniki (MITRE ATT&CK)

| Technika | Opis |
|--------|-----|
| Ransomware | Szyfrowanie AES-256 w pamięci + interakcja z VSS |
| Credential Access | Próba dostępu do procesu LSASS (`OpenProcess`) |
| Persistence | Modyfikacja klucza `Run` w rejestrze |
| Command & Control | HTTPS beacon (`/favicon.ico`) |
| Process Injection (bezpieczne) | Enumeracja uchwytów procesów |
| Keylogging (audit-safe) | Globalny hook klawiatury z `CallNextHookEx` |

Wszystkie testy są **odwracalne, niedestrukcyjne i bezpieczne**.

---

## 🛡️ Stabilność i bezpieczeństwo

- poprawna obsługa **Garbage Collectora** (delegaty globalne)  
- zgodność z kontraktami **WinAPI**  
- brak blokowania interfejsu użytkownika (WPF Dispatcher)  
- automatyczne czyszczenie po testach  
- rozpoznawanie kontekstu uruchomienia (Administrator / User)  

Narzędzie **nie omija zabezpieczeń**, lecz **sprawdza, czy one działają**.

---

## 📊 Raportowanie HTML

Wbudowany silnik raportowania generuje **czytelny raport HTML**, zawierający:

- chronologiczną listę zdarzeń  
- kolorowe oznaczenia (ALERT / BLOCK / FAIL)  
- podsumowanie skuteczności ochrony  
- informacje o hoście, użytkowniku i czasie testów  

Raport jest przeznaczony zarówno dla zespołów technicznych, jak i decyzyjnych.

---

## 🖥️ Interfejs użytkownika

- PowerShell + WPF  
- czytelny i stabilny interfejs  
- osobne przyciski dla każdego scenariusza  
- paski postępu  
- generowanie raportu jednym kliknięciem  

---

## 🚀 Zastosowania

- audyt skuteczności XDR / EDR  
- weryfikacja widoczności SOC  
- testy Purple Team  
- laboratoria bezpieczeństwa  
- projekty akademickie (prace inżynierskie, dyplomowe)  
- wewnętrzne testy bezpieczeństwa  

---

## ⚠️ Zastrzeżenie

Projekt **nie jest złośliwym oprogramowaniem** i **nie służy do nieautoryzowanych działań**.

Nie wykorzystuje podatności, nie kradnie danych i nie powoduje trwałych zmian w systemie.

Uruchamiaj wyłącznie:
- na własnych systemach  
- lub w środowiskach, na które posiadasz zgodę  

---

## 👤 Autor i cel

Projekt został stworzony jako **narzędzie inżynierii bezpieczeństwa**, z naciskiem na:

- stabilność  
- poprawność implementacji niskopoziomowych API  
- wartość audytową  
- czytelność wyników  

Odzwierciedla realne procesy **Blue Team / Purple Team / Security Engineering**.

---

## 📄 Licencja

Rekomendowane:
- **MIT** – do celów edukacyjnych i portfolio  
- **Apache 2.0** – przyjazna środowiskom enterprise  

---

## 🔚 Status projektu

**v5.2 – projekt ukończony funkcjonalnie**

Dalszy rozwój możliwy w kierunku:
- analizy porównawczej XDR  
- mapowania pokrycia MITRE  
- automatyzacji testów  

Nie w kierunku zwiększania agresywności testów.
