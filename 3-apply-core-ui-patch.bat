@echo off
rem Test C: replaces core thing bundle and Main UI in oh53-lean with the patched ones. Stop openHAB first.
set T=%~dp0oh53-lean
if not exist "%T%\runtime\system\org\openhab\core\bundles\org.openhab.core.thing\5.3.0-SNAPSHOT" (echo oh53-lean not found or never started & pause & exit /b 1)
copy /y "%~dp0core-patch\org.openhab.core.thing-5.3.0-SNAPSHOT.jar" "%T%\runtime\system\org\openhab\core\bundles\org.openhab.core.thing\5.3.0-SNAPSHOT\org.openhab.core.thing-5.3.0-SNAPSHOT.jar"
copy /y "%~dp0ui-patch\org.openhab.ui-5.3.0-SNAPSHOT.jar" "%T%\runtime\system\org\openhab\ui\bundles\org.openhab.ui\5.3.0-SNAPSHOT\org.openhab.ui-5.3.0-SNAPSHOT.jar"
if exist "%T%\userdata\cache.ui-patch" rmdir /s /q "%T%\userdata\cache.ui-patch"
if exist "%T%\userdata\tmp.ui-patch" rmdir /s /q "%T%\userdata\tmp.ui-patch"
ren "%T%\userdata\cache" cache.ui-patch
ren "%T%\userdata\tmp" tmp.ui-patch
echo Patched. Start again with 2-start-lean.bat
pause
