@echo off
REM Windows Batch wrapper for Hedge Scheduler PowerShell script
REM This makes it easier to call from Command Prompt

powershell.exe -ExecutionPolicy Bypass -File "%~dp0get_hedge_service.ps1" -Action %1

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo For help, run: get_hedge_service.bat
    exit /b %ERRORLEVEL%
)