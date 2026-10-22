@echo off
rem Test A: 5.2 baseline (with add-on "modbus") -> 5.3 with split add-ons. Run 0-create-oh52-baseline.bat first and configure it.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modbus-split-test\Setup-OpenHabTest.ps1" -Mode Upgrade -From "%~dp0oh52" -Target "%~dp0oh53-legacy"
pause
