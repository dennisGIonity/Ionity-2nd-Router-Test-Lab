@echo off
rem AEDI - IONITY GLOBAL | Ionity Lab - start the lab broker and every registered project
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lab.ps1" start
echo.
pause
