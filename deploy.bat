@echo off
:: =============================================================================
::  deploy.bat
::  KBU Workstation Deployment Tool — Launcher
::
::  Detects the project directory, checks for administrator privileges,
::  and launches the PowerShell-based deployment engine.
::
::  Usage: Right-click → Run as Administrator
:: =============================================================================

:: ---------- UTF-8 code page ----------
chcp 65001 >nul 2>&1

:: ---------- Detect project root ----------
if defined KBU_USB_ROOT (
    set "PROJECT_DIR=%KBU_USB_ROOT%"
) else (
    set "PROJECT_DIR=%~dp0"
)
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

:: ---------- Check administrator privileges ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   [X] Administrator privileges required!
    echo.
    echo   Please right-click deploy.bat and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

:: ---------- Launch PowerShell deployment engine ----------
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\src\Deploy.ps1"

:: ---------- Keep window open on error ----------
if %errorlevel% neq 0 (
    echo.
    echo   [!] Deployment engine exited with error code %errorlevel%.
    echo.
    pause
)
