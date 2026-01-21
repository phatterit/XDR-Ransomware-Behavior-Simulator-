/*
 * XDR-Tester Native v2.1 (English/ASCII Edition)
 * Architecture: Modular Monolith
 * Changes: Converted all strings to English to fix CLI encoding issues.
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

// Linking System Libraries
#pragma comment(lib, "User32.lib")
#pragma comment(lib, "Advapi32.lib")
#pragma comment(lib, "Wininet.lib")
#pragma comment(lib, "Crypt32.lib")
#pragma comment(lib, "Kernel32.lib")

using namespace std;

// ============================================================================
// 1. CONFIGURATION
// ============================================================================
namespace Config {
    const bool DRY_RUN = false;             // Dry run mode (logs only, no API calls)
    const int  RANSOM_LOOPS = 20;           // Number of encryption loops
    const int  VSS_TIMEOUT_MS = 5000;       // VSSAdmin timeout
    const int  PROC_ENUM_LIMIT = 15;        // Process enumeration limit
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
    static Logger& Get() {
        static Logger instance;
        return instance;
    }

    void Log(string msg, string type = "INFO") {
        string time = GetTimeStr();
        entries.push_back({ time, type, msg });

        if (type == "TEST") countTests++;
        if (type == "ALERT") countAlert++; // Breach
        if (type == "BLOCK" || type == "FAIL") countBlock++; // Blocked/Safe

        // Disk write
        ofstream f(Config::LOG_FILE, ios::app);
        if (f.is_open()) {
            f << time << "|" << type << "|" << msg << "\n";
            f.close();
        }

        // Console Colors
        HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        if (type == "ALERT") SetConsoleTextAttribute(hConsole, 12);      // Red
        else if (type == "BLOCK") SetConsoleTextAttribute(hConsole, 10); // Green
        else if (type == "FAIL") SetConsoleTextAttribute(hConsole, 10);  // Green
        else if (type == "WARN") SetConsoleTextAttribute(hConsole, 14);  // Yellow
        else if (type == "ACT") SetConsoleTextAttribute(hConsole, 11);   // Cyan
        else if (type == "TEST") SetConsoleTextAttribute(hConsole, 15);  // Bright White
        else SetConsoleTextAttribute(hConsole, 7); // Default

        cout << "[" << time << "] [" << type << "] " << msg << endl;
        SetConsoleTextAttribute(hConsole, 7);
    }

    const vector<LogEntry>& GetEntries() const { return entries; }
    int GetAlerts() const { return countAlert; }
    int GetBlocks() const { return countBlock; }
    int GetTotalTests() const { return countTests; }
};

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
        
        string riskLevel = "LOW";
        string riskColor = "#27ae60"; // Green
        if (alerts > 0) { riskLevel = "MEDIUM"; riskColor = "#f39c12"; }
        if (alerts > 2) { riskLevel = "HIGH"; riskColor = "#c0392b"; }

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
        f << ".FAIL{background:#d4efdf;color:#27ae60}";
        f << ".TEST{background:#d6eaf8;font-weight:bold;border-top:2px solid #3498db}";
        f << "</style></head><body><div class='container'>";
        
        f << "<h1>XDR Audit Report</h1>";
        f << "<div class='summary'>";
        f << "<div class='card'><div class='num'>" << total << "</div><div>Scenarios</div></div>";
        f << "<div class='card'><div class='num' style='color:#c0392b'>" << alerts << "</div><div>Breached (Gaps)</div></div>";
        f << "<div class='card'><div class='num' style='color:#27ae60'>" << blocks << "</div><div>Blocked (Secure)</div></div>";
        f << "<div class='card'><div>Risk Level</div><div class='risk'>" << riskLevel << "</div></div>";
        f << "</div>";

        f << "<table><tr><th>Time</th><th>Type</th><th>Event</th></tr>";
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

        LOG("Report generated: " + Config::REPORT_FILE, "INFO");
        string cmd = "start " + Config::REPORT_FILE;
        system(cmd.c_str());
    }
};

// ============================================================================
// 4. TEST MODULES
// ============================================================================
class TestModule {
protected:
    bool IsDryRun() { return Config::DRY_RUN; }
};

class RansomwareTest : public TestModule {
public:
    void Run() {
        LOG("=== SCENARIO: Ransomware Simulation ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Skipped crypto & vssadmin.", "INFO"); return; }

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
                if (success) LOG("Encrypted " + to_string(Config::RANSOM_LOOPS) + " memory blocks (AES-256).", "OK");
                else LOG("Encryption error.", "FAIL");
            }
            if (hKey) CryptDestroyKey(hKey);
            CryptReleaseContext(hProv, 0);
        } else {
            LOG("CryptoAPI Init Error.", "ERR");
        }

        // 2. VSSAdmin
        LOG("Starting vssadmin list shadows...", "ACT");
        STARTUPINFOA si = { sizeof(si) }; PROCESS_INFORMATION pi;
        char cmd[] = "vssadmin.exe List Shadows";
        
        if (CreateProcessA(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
            if (WaitForSingleObject(pi.hProcess, Config::VSS_TIMEOUT_MS) == WAIT_TIMEOUT) {
                LOG("TIMEOUT: vssadmin hung (XDR Block?)", "BLOCK");
                TerminateProcess(pi.hProcess, 1);
            } else {
                LOG("vssadmin finished successfully.", "OK");
            }
            CloseHandle(pi.hProcess); CloseHandle(pi.hThread);
        } else {
            LOG("vssadmin CreateProcess failed.", "FAIL");
        }
    }
};

class LsassTest : public TestModule {
public:
    void Run() {
        LOG("=== SCENARIO: Credential Access (LSASS) ===", "TEST");
        // NOTE: This test intentionally stops at OpenProcess.
        // No memory read is performed to keep test non-destructive/audit-safe.
        
        if (IsDryRun()) { LOG("[DRY RUN] Skipped OpenProcess.", "INFO"); return; }

        DWORD pid = GetLsassPid();
        if (pid == 0) { LOG("LSASS process not found (No Admin?)", "WARN"); return; }

        LOG("Attempting OpenProcess (VM_READ) on PID: " + to_string(pid), "ACT");
        
        HANDLE hLsass = OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, FALSE, pid);
        if (hLsass) {
            LOG("SUCCESS: Handle opened to LSASS! (Security Gap)", "ALERT");
            CloseHandle(hLsass);
        } else {
            DWORD err = GetLastError();
            LOG("BLOCKED: Access Denied (Err: " + to_string(err) + ")", "BLOCK");
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
        LOG("=== SCENARIO: Persistence (Registry) ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Skipped registry write.", "INFO"); return; }

        HKEY hKey;
        const char* path = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";
        const char* val = "XDR_Native_Audit";

        long res = RegOpenKeyExA(HKEY_CURRENT_USER, path, 0, KEY_SET_VALUE, &hKey);
        if (res == ERROR_SUCCESS) {
            LOG("Attempting to add Registry Run key...", "ACT");
            res = RegSetValueExA(hKey, val, 0, REG_SZ, (const BYTE*)"calc.exe", 9);
            
            if (res == ERROR_SUCCESS) {
                LOG("Registry key created successfully! (Gap)", "ALERT");
                Sleep(200);
                RegDeleteValueA(hKey, val);
                LOG("Cleanup: Key removed.", "INFO");
            } else {
                LOG("BLOCKED: Registry write failed.", "BLOCK");
            }
            RegCloseKey(hKey);
        } else {
            LOG("Error opening Run key.", "ERR");
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
        LOG("=== SCENARIO: Injection & Hooking ===", "TEST");
        if (IsDryRun()) { LOG("[DRY RUN] Skipped Hook/OpenProcess.", "INFO"); return; }

        // 1. Hooking
        LOG("Attempting Global Keyboard Hook...", "ACT");
        HHOOK hHook = SetWindowsHookExA(WH_KEYBOARD_LL, SafeHookProc, NULL, 0);
        if (hHook) {
            LOG("SUCCESS: Hook installed! (Keylogger possible)", "ALERT");
            Sleep(500);
            UnhookWindowsHookEx(hHook);
        } else {
            LOG("BLOCKED: SetWindowsHookEx failed.", "BLOCK");
        }

        // 2. Enum
        LOG("Scanning processes...", "ACT");
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
        LOG("Enumeration finished for " + to_string(count) + " processes.", "INFO");
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
    SetConsoleTitleA("XDR Audit Tool v2.1 (Enterprise)");
    
    // Clear log file
    remove(Config::LOG_FILE.c_str());

    cout << "========================================" << endl;
    cout << "   XDR AUDIT TOOL - ENTERPRISE EDITION  " << endl;
    cout << "========================================" << endl;

    if (IsAdmin()) LOG("Admin Privileges: YES", "INFO");
    else LOG("Admin Privileges: NO (Results might be limited)", "WARN");

    if (Config::DRY_RUN) LOG("DRY RUN MODE: ACTIVE (Safe Simulation)", "WARN");

    cout << "\nPress ENTER to start audit..." << endl;
    cin.get();

    // Execute Tests
    RansomwareTest().Run();
    LsassTest().Run();
    PersistenceTest().Run();
    InjectionTest().Run();

    cout << "\n----------------------------------------" << endl;
    LOG("Audit finished.", "INFO");
    
    // Generate Report
    ReportGenerator::Generate();

    cout << "Press ENTER to exit..." << endl;
    cin.get();
    return 0;
}