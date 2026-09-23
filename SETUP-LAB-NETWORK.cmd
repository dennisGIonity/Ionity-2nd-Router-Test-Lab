@echo off
rem AEDI - IONITY GLOBAL | Ionity Lab - one-click laptop network setup
rem Household WiFi = internet, H3C Ethernet = lab only. Asks for admin (UAC).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0network\setup_lab_network.ps1"
