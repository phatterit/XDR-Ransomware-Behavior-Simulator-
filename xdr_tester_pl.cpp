/*
 * XDR-Tester Native v2.0 (Enterprise Edition)
 * Architektura: Modularna (zdefiniowana w jednym pliku dla łatwej kompilacji)
 * Funkcje: Dual-Logging, HTML Scoring, Safety Guardrails, Configurable
 */

#define _CRT_SECURE_NO_WARNINGS

#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <tlhelp32.h>
#include <wininet.h>
#include <wincrypt.h>
#include <ctime>
#include <iomanip>
#include <sstream>

// Linkowanie
#pragma comment(lib, "User32.lib")
#pragma comment(lib, "Advapi32.lib")
#pragma comment(lib, "Wininet.lib")
#pragma comment(lib, "Crypt32.lib")
#pragma comment(lib, "Kernel32.lib")

using namespace std;

// ============================================================================
// 1. CONFIGURATION (PARAMETRYZACJA)
// ============================================================================
namespace Config {
    const bool DRY_RUN = false;             // Tryb "na sucho" (tylko logi, bez API)
    const int  RANSOM_LOOPS = 20;           // Ilość iteracji szyfrowania
    const int  VSS_TIMEOUT_MS = 5000;       // Timeout dla vssadmin
    const int  PROC_ENUM_LIMIT = 15;        // Limit skanowanych procesów
    const string LOG_FILE = string(getenv("TEMP")) + "\\XDR_Audit_Log.txt";
    const string REPORT_FILE = string(getenv("TEMP")) + "\\XDR_Audit_Report.html";
}

// ============================================================================
// 2. CORE: LOGGER & UTILS
// ============================================================================
struct LogEntry {
    string time;
    string type; // INFO, ACT, OK, FAIL, BLOCK, ALERT
    string msg;
};

class Logger {
private:
    vector<LogEntry> entries;
    int countAlert = 0;
    int countBlock = 0;
    int countTests = 0;

    string GetTimeStr() {
        time_t now = time(0);
        struct tm tstruct;
        char buf[80];
        localtime_s(&tstruct, &now);
        strftime(buf, sizeof(buf), "%H:%M:%S", &tstruct);
        return string(buf);
    }

public:
    // Singleton
    static Logger& Get() {
        static Logger instance;
        return instance;
    }

    // Dual-Logging: RAM + Disk (Immediate flush)
    void Log(string msg, string type = "INFO") {
        string time = GetTimeStr();
        entries.push_back({ time, type, msg });

        // Aktualizacja statystyk
        if (type == "TEST") countTests++;
        if (type == "ALERT") countAlert++; // Atak udany (Luka)
        if (type == "BLOCK" || type == "FAIL") countBlock++; // Atak zablokowany (Sukces XDR)

        // Zapis na dysk (Append mode)
        ofstream f(Config::LOG_FILE, ios::app);
        if (f.is_open()) {
            f << time << "|" << type << "|" << msg << "\n";
            f.close();
        }

        // Konsola z kolorami
        HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        if (type == "ALERT") SetConsoleTextAttribute(hConsole, 12);      // Czerwony (Zagrożenie)
        else if (type == "BLOCK") SetConsoleTextAttribute(hConsole, 10); // Zielony (Ochrona)
        else if (type == "FAIL") SetConsoleTextAttribute(hConsole, 10);  // Zielony (Blokada to też Fail ataku)
        else if (type == "WARN") SetConsoleTextAttribute(hConsole, 14);  // Żółty
        else if (type == "ACT") SetConsoleTextAttribute(hConsole, 11);   // Cyjan
        else if (type == "TEST") SetConsoleTextAttribute(hConsole, 15);  // Biały Jasny
        else SetConsoleTextAttribute(hConsole, 7);

        cout << "[" << time << "] [" << type << "] " << msg << endl;
        SetConsoleTextAttribute(hConsole, 7);
    }

    const vector<LogEntry>& GetEntries() const { return entries; }
    int GetAlerts() const { return countAlert; }
    int GetBlocks() const { return countBlock; }
    int GetTotalTests() const { return countTests; }
};

// Makro dla wygody
#define LOG(msg, type) Logger::Get().Log(msg, type)

// ============================================================================
// 3. CORE: REPORT GENERATOR
// ============================================================================
class ReportGenerator {
public:
    static void Generate() {
        ofstream f(Config::REPORT_FILE);
        if (!f.is_open()) return;

        int alerts = Logger::Get().GetAlerts();
        int blocks = Logger::Get().GetBlocks();
        int total = Logger::Get().GetTotalTests();
        
        // Obliczanie ryzyka
        string riskLevel = "NISKI";
        string riskColor = "#27ae60"; // Green
        if (alerts > 0) { riskLevel = "ŚREDNI"; riskColor = "#f39c12"; }
        if (alerts > 2) { riskLevel = "WYSOKI"; riskColor = "#c0392b"; }

        f << "<!DOCTYPE html><html><head><meta charset='UTF-8'><style>";
        f << "body{font-family:'Segoe UI',sans-serif;background:#ecf0f1;padding:20px;color:#2c3e50}";
        f << ".container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}";
        f << "h1{text-align:center;border-bottom:2px solid #bdc3c7;padding-bottom:10px}";
        f << ".summary{display:flex;justify-content:space-around;background:#f7f9fa;padding:15px;border-radius:5px;margin-bottom:20px}";
        f << ".card{text-align:center} .num{font-size:24px;font-weight:bold}";
        f << ".risk{font-size:18px;font-weight:bold;color:" << riskColor << "}";
        f << "table{width:100%;border-collapse:collapse;margin-top:10px}";
        f << "th{background:#34495e;color:white;padding:10px;text-align:left}";
        f << "td{padding:8px;border-bottom:1px solid #ddd}";
        f << ".ALERT{background:#fadbd8;color:#c0392b;font-weight:bold}";
        f << ".BLOCK{background:#d4efdf;color:#27ae60;font-weight:bold}";
        f << ".FAIL{background:#d4efdf;color:#27ae60}"; // Fail ataku to dobrze
        f << ".TEST{background:#d6eaf8;font-weight:bold;border-top:2px solid #3498db}";
        f << "</style></head><body><div class='container'>";
        
        f << "<h1>Raport Audytu XDR</h1>";
        f << "<div class='summary'>";
        f << "<div class='card'><div class='num'>" << total << "</div><div>Scenariusze</div></div>";
        f << "<div class='card'><div class='num' style='color:#c0392b'>" << alerts << "</div><div>Przełamane (Luki)</div></div>";
        f << "<div class='card'><div class='num' style='color:#27ae60'>" << blocks << "</div><div>Zablokowane</div></div>";
        f << "<div class='card'><div>Poziom Ryzyka</div><div class='risk'>" << riskLevel << "</div></div>";
        f << "</div>";

        f << "<table><tr><th>Czas</th><th>Typ</th><th>Zdarzenie</th></tr>";
        for (const auto& l : Logger::Get().GetEntries()) {
            string rowClass = "";
            if (l.type == "ALERT") rowClass = "ALERT";
            else if (l.type == "BLOCK") rowClass = "BLOCK";
            else if (l.type == "FAIL") rowClass = "FAIL";
            else if (l.type == "TEST") rowClass = "TEST";
            
            f << "<tr class='" << rowClass << "'><td>" << l.time << "</td><td>" << l.type << "</td><td>" << l.msg << "</td></tr>";
        }
        f << "</table></div></body></html>";
        f.close();

        LOG("Raport wygenerowany: " + Config::REPORT_FILE, "INFO");
        string cmd = "start " + Config::REPORT_FILE;
        system(cmd.c_str());
    }
};

// ============================================================================
// 4. TEST MODULES
// ============================================================================

// Klasa bazowa dla testów (opcjonalna, ale dobra dla architektury)
class TestModule {
protected:
    bool IsDryRun() { return Config::DRY_RUN; }
};

class RansomwareTest : public TestModule {
public:
    void Run() {
        LOG("=== SCENARIUSZ: Ransomware Simulation ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Pominięto krypto i vssadmin.", "INFO"); return; }

        HCRYPTPROV hProv = 0; HCRYPTKEY hKey = 0;
        
        // 1. Crypto Stress
        if (CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT)) {
            if (CryptGenKey(hProv, CALG_AES_256, CRYPT_EXPORTABLE, &hKey)) {
                BYTE chunk[1024];
                bool success = true;
                for (int i = 0; i < Config::RANSOM_LOOPS; i++) {
                    DWORD len = 1024;
                    CryptGenRandom(hProv, len, chunk);
                    if (!CryptEncrypt(hKey, 0, TRUE, 0, chunk, &len, 1024)) success = false;
                }
                if (success) LOG("Zaszyfrowano " + to_string(Config::RANSOM_LOOPS) + " bloków pamięci (AES-256).", "OK");
                else LOG("Błąd szyfrowania.", "FAIL");
            }
            if (hKey) CryptDestroyKey(hKey);
            CryptReleaseContext(hProv, 0);
        } else {
            LOG("Błąd inicjalizacji CryptoAPI.", "ERR");
        }

        // 2. VSSAdmin
        LOG("Uruchamianie vssadmin list shadows...", "ACT");
        STARTUPINFOA si = { sizeof(si) }; PROCESS_INFORMATION pi;
        char cmd[] = "vssadmin.exe List Shadows";
        
        if (CreateProcessA(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
            if (WaitForSingleObject(pi.hProcess, Config::VSS_TIMEOUT_MS) == WAIT_TIMEOUT) {
                LOG("TIMEOUT: vssadmin zawieszony (XDR Block?)", "BLOCK");
                TerminateProcess(pi.hProcess, 1);
            } else {
                LOG("vssadmin zakończony pomyślnie.", "OK");
            }
            CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
        } else {
            LOG("Błąd CreateProcess vssadmin.", "FAIL");
        }
    }
};

class LsassTest : public TestModule {
public:
    void Run() {
        LOG("=== SCENARIUSZ: Credential Access (LSASS) ===", "TEST");
        // NOTE: This test intentionally stops at OpenProcess.
        // No memory read is performed to keep test non-destructive/audit-safe.
        
        if (IsDryRun()) { LOG("[DRY RUN] Pominięto OpenProcess.", "INFO"); return; }

        DWORD pid = GetLsassPid();
        if (pid == 0) { LOG("Nie znaleziono procesu LSASS (Brak Admina?)", "WARN"); return; }

        LOG("Próba OpenProcess (VM_READ) na PID: " + to_string(pid), "ACT");
        
        // Próba otwarcia
        HANDLE hLsass = OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, FALSE, pid);
        if (hLsass) {
            LOG("SUKCES: Otwarto uchwyt do LSASS! (Luka bezpieczeństwa)", "ALERT");
            CloseHandle(hLsass);
        } else {
            DWORD err = GetLastError();
            LOG("BLOKADA: Odmowa dostępu (Err: " + to_string(err) + ")", "BLOCK");
        }
    }

private:
    DWORD GetLsassPid() {
        HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        PROCESSENTRY32 pe32 = { sizeof(pe32) };
        DWORD pid = 0;
        if (Process32First(hSnap, &pe32)) {
            do {
                if (strcmp(pe32.szExeFile, "lsass.exe") == 0) { pid = pe32.th32ProcessID; break; }
            } while (Process32Next(hSnap, &pe32));
        }
        CloseHandle(hSnap);
        return pid;
    }
};

class PersistenceTest : public TestModule {
public:
    void Run() {
        LOG("=== SCENARIUSZ: Persistence (Registry) ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Pominięto zapis rejestru.", "INFO"); return; }

        HKEY hKey;
        const char* path = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
        const char* val = "XDR_Native_Audit";

        long res = RegOpenKeyExA(HKEY_CURRENT_USER, path, 0, KEY_SET_VALUE, &hKey);
        if (res == ERROR_SUCCESS) {
            LOG("Próba dodania wpisu do Autostartu...", "ACT");
            res = RegSetValueExA(hKey, val, 0, REG_SZ, (const BYTE*)"calc.exe", 9);
            
            if (res == ERROR_SUCCESS) {
                LOG("Wpis utworzony pomyślnie! (Luka)", "ALERT");
                Sleep(200);
                RegDeleteValueA(hKey, val);
                LOG("Cleanup: Wpis usunięty.", "INFO");
            } else {
                LOG("BLOKADA: Błąd zapisu do rejestru.", "BLOCK");
            }
            RegCloseKey(hKey);
        } else {
            LOG("Błąd otwarcia klucza Run.", "ERR");
        }
    }
};

class InjectionTest : public TestModule {
    // Global keyboard hook used only to generate telemetry.
    // No keystrokes are collected or processed.
    static LRESULT CALLBACK SafeHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
        return CallNextHookEx(NULL, nCode, wParam, lParam);
    }

public:
    void Run() {
        LOG("=== SCENARIUSZ: Injection & Hooking ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Pominięto Hook/OpenProcess.", "INFO"); return; }

        // 1. Hooking
        LOG("Próba instalacji Global Keyboard Hook...", "ACT");
        HHOOK hHook = SetWindowsHookExA(WH_KEYBOARD_LL, SafeHookProc, NULL, 0);
        if (hHook) {
            LOG("SUKCES: Hook zainstalowany! (Keylogger możliwy)", "ALERT");
            Sleep(500);
            UnhookWindowsHookEx(hHook);
        } else {
            LOG("BLOKADA: SetWindowsHookEx zablokowany.", "BLOCK");
        }

        // 2. Enum
        LOG("Skanowanie procesów...", "ACT");
        HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        PROCESSENTRY32 pe32 = { sizeof(pe32) };
        int count = 0;
        if (Process32First(hSnap, &pe32)) {
            do {
                HANDLE hProc = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pe32.th32ProcessID);
                if (hProc) CloseHandle(hProc);
                count++;
            } while (Process32Next(hSnap, &pe32) && count < Config::PROC_ENUM_LIMIT);
        }
        CloseHandle(hSnap);
        LOG("Zakończono enumerację " + to_string(count) + " procesów.", "INFO");
    }
};

// ============================================================================
// 5. MAIN
// ============================================================================
bool IsAdmin() {
    BOOL fRet = FALSE; HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        TOKEN_ELEVATION Elevation; DWORD cbSize = sizeof(TOKEN_ELEVATION);
        if (GetTokenInformation(hToken, TokenElevation, &Elevation, sizeof(Elevation), &cbSize)) {
            fRet = Elevation.TokenIsElevated;
        }
    }
    if (hToken) CloseHandle(hToken);
    return fRet;
}

int main() {
    SetConsoleTitleA("XDR Audit Tool v2.0 (Enterprise)");
    
    // Inicjalizacja pliku logu
    remove(Config::LOG_FILE.c_str());

    cout << "========================================" << endl;
    cout << "   XDR AUDIT TOOL - ENTERPRISE EDITION  " << endl;
    cout << "========================================" << endl;

    if (IsAdmin()) LOG("Uprawnienia Administratora: TAK", "INFO");
    else LOG("Uprawnienia Administratora: NIE (Wyniki mogą być niepełne)", "WARN");

    if (Config::DRY_RUN) LOG("TRYB DRY RUN: AKTYWNY (Bezpieczna symulacja)", "WARN");

    cout << "\nNacisnij ENTER aby rozpoczac audyt..." << endl;
    cin.get();

    // Wykonanie testów
    RansomwareTest().Run();
    LsassTest().Run();
    PersistenceTest().Run();
    InjectionTest().Run();
    // Można dodać NetworkTest tutaj analogicznie

    cout << "\n----------------------------------------" << endl;
    LOG("Audyt zakończony.", "INFO");
    
    // Generowanie raportu
    ReportGenerator::Generate();

    cout << "Nacisnij ENTER aby zakonczyc..." << endl;
    cin.get();
    return 0;
}