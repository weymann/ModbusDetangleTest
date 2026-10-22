@echo off
rem Test D: fresh instance with patched core+UI, to install ONLY "Modbus Core Binding"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modbus-split-test\Setup-OpenHabTest.ps1" -Mode Fresh -Target "%~dp0oh53-core"
pause
