@echo off
rem Test B: fresh openHAB 5.3 snapshot with the split Modbus add-ons (lean install)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modbus-split-test\Setup-OpenHabTest.ps1" -Mode Fresh -Target "%~dp0oh53-lean"
pause
