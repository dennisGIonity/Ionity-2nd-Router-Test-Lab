@echo off
rem AEDI - IONITY GLOBAL | Ionity Lab - put the lab WiFi into every registered project's boards
rem You type the password here; it goes only into each project's git-ignored secrets.h.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0network\set_lab_wifi.ps1"
echo.
pause
