@echo off
rem Creates a stock openHAB 5.2 instance (oh52). Adjust VER if 5.2.0 is not available.
set VER=5.2.0
powershell -NoProfile -Command "$z=\"$env:TEMP\openhab-%VER%.zip\"; if(!(Test-Path $z)){Invoke-WebRequest 'https://github.com/openhab/openhab-distro/releases/download/%VER%/openhab-%VER%.zip' -OutFile $z}; Expand-Archive $z '%~dp0oh52'"
echo Now start oh52\start.bat, install add-on "Modbus Binding" in the UI, create Modbus TCP Slave + e.g. E3DC thing, then stop it.
pause
