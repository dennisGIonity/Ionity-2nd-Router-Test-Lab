@echo off
rem AEDI - IONITY GLOBAL | Ionity Lab - Pi 5 setup. Double-click.
rem   1. pauses GateFlame (reversible - RESUME-GATEFLAME.cmd undoes it)
rem   2. puts the live dashboard on the Pi's screen (ASUS)
rem You type YOUR SSH key passphrase (if not already loaded) and YOUR Pi sudo password.
"C:\Program Files\Git\bin\bash.exe" -l "%~dp0pi\pi-gateflame.sh" lab-setup
echo.
pause
