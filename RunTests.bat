@echo off
setlocal enabledelayedexpansion

:: --- Header
echo ================================================
echo      Ransomware Behavior Simulation Launcher
echo ================================================
echo.

:: Sprawdź, czy skrypty są w tym samym folderze
for %%f in (Test-Low.ps1 Test-Medium.ps1 Test-High.ps1) do (
    if not exist "%%f" (
        echo [ERROR] Brak pliku: %%f
        echo Upewnij się, że .BAT i .PS1 są w tym samym katalogu.
        pause
        exit /b
    )
)

echo Wybierz test, ktory chcesz uruchomic:
echo 1 - Low
echo 2 - Medium
echo 3 - High
set /p choice=Podaj numer: 

if "%choice%"=="1" set script=Test-Low.ps1
if "%choice%"=="2" set script=Test-Medium.ps1
if "%choice%"=="3" set script=Test-High.ps1

if not defined script (
    echo Niepoprawny wybor.
    pause
    exit /b
)

echo.
echo Uruchamiam %script%...
powershell -NoProfile -ExecutionPolicy Bypass -File "%script%"
echo.
pause
