# 🇬🇧 **README_EN.md**

```markdown
# Safe Ransomware Behavior Simulations – XDR/EDR Testing

This repository contains **3 levels of safe ransomware-behavior simulations**
designed to test XDR/EDR detection capabilities without harming any files.

## ✔ The scripts do NOT:
- encrypt files  
- delete data  
- modify user content  
- cause any destructive or persistent changes  

## Test levels:
1. **Test-Low.ps1** – low-intensity crypto simulation (RAM)
2. **Test-Medium.ps1** – I/O + crypto + rapid access patterns
3. **Test-High.ps1** – aggressive ransomware‑like behavior patterns

## MITRE ATT&CK Mapping:
- T1059.001 – PowerShell Execution  
- T1083 – File Discovery  
- T1486 – Data Encrypted for Impact (simulated only)  
- T1490 – Inhibit System Recovery (behavioral similarity)  

## Usage
Run PowerShell as administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Test-High.ps1
