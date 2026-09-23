@echo off
rem AEDI - IONITY GLOBAL | Ionity Lab - health check. Every line should be OK before a demo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0network\lab_status.ps1"
echo.
pause
