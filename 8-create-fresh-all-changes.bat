@echo off
rem Fresh openHAB 5.3 snapshot with ALL changes (split Modbus add-ons + patched core thing bundle + patched Main UI).
rem No presets: no conf, no things, no add-ons installed.
set T=%~dp0oh53-all
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modbus-split-test\Setup-OpenHabTest.ps1" -Mode Fresh -Target "%T%"
if errorlevel 1 (pause & exit /b 1)
mkdir "%T%\runtime\system\org\openhab\core\bundles\org.openhab.core.thing\5.3.0-SNAPSHOT" 2>nul
mkdir "%T%\runtime\system\org\openhab\ui\bundles\org.openhab.ui\5.3.0-SNAPSHOT" 2>nul
copy /y "%~dp0core-patch\org.openhab.core.thing-5.3.0-SNAPSHOT.jar" "%T%\runtime\system\org\openhab\core\bundles\org.openhab.core.thing\5.3.0-SNAPSHOT\"
copy /y "%~dp0ui-patch\org.openhab.ui-5.3.0-SNAPSHOT.jar" "%T%\runtime\system\org\openhab\ui\bundles\org.openhab.ui\5.3.0-SNAPSHOT\"
echo Done. Start with 9-start-fresh-all-changes.bat
pause
