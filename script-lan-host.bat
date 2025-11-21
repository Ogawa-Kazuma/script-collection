@echo off
setlocal enabledelayedexpansion

:: Set your subnet here
set SUBNET=192.168.6

:: Output files
set ACTIVE=active-ips.txt
set UNUSED=unused-ips.txt

echo Scanning %SUBNET%.0/24 ...
echo. > %ACTIVE%
echo. > %UNUSED%

for /L %%i in (1,1,254) do (
    set IP=%SUBNET%.%%i
    ping -n 1 -w 200 !IP! >nul
    if !errorlevel! == 0 (
        echo !IP! is ACTIVE
        echo !IP! >> %ACTIVE%
    ) else (
        echo !IP! is UNUSED
        echo !IP! >> %UNUSED%
    )
)

echo.
echo ✅ Scan complete!
echo 🟢 Active IPs saved to: %ACTIVE%
echo ⚪ Unused IPs saved to: %UNUS
