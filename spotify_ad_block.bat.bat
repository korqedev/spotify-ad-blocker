@echo off
color 00
cls

:: Enable ANSI escape codes on Windows 10+
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Define color codes
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "GRAY=%ESC%[90m"

echo.
echo.
echo %CYAN%   ##  ##   ####   ## ##    ####   #####   #####   #####   ##  ##%RESET%
echo %CYAN%   ## ##   ##  ##  ####    ##  ##  ##      ##  ##  ##      ##  ##%RESET%
echo %CYAN%   ####    ##  ##  ###     ##  ##  #####   ##  ##  #####    ####%RESET%
echo %CYAN%   ## ##   ##  ##  ## ##   #####   ##      ##  ##  ##        ##%RESET%
echo %CYAN%   ##  ##   ####   ##  ##     ##   #####   #####   #####     ##%RESET%
echo.
echo.
echo %GRAY%   ==========================================================%RESET%
echo %BOLD%%WHITE%    SPOTIFY OPTIMIZATION + SPICETIFY INSTALLER  %GRAY%// KORQDEV%RESET%
echo %GRAY%   ==========================================================%RESET%
echo %GRAY%    User: %CYAN%%USERNAME%  %GRAY%^|  Machine: %CYAN%%COMPUTERNAME%%RESET%
echo %GRAY%   ==========================================================%RESET%
echo.
echo %GRAY%    [%CYAN%1/3%GRAY%]  Preparing environment...%RESET%
echo %GRAY%    [%CYAN%2/3%GRAY%]  Fetching latest Spicetify build...%RESET%
echo %GRAY%    [%CYAN%3/3%GRAY%]  Installing and applying optimizations...%RESET%
echo.
echo %GRAY%   ----------------------------------------------------------%RESET%
echo %WHITE%    Press any key to begin...%RESET%
pause >nul

echo.
echo %GRAY%   [%CYAN%~%GRAY%]  Checking if Spotify is running...%RESET%

tasklist /FI "IMAGENAME eq Spotify.exe" 2>nul | find /I "Spotify.exe" >nul

if %ERRORLEVEL%==0 (
    echo %GRAY%   [%YELLOW%!%GRAY%]  Spotify is currently open.%RESET%
    echo %GRAY%   [%CYAN%~%GRAY%]  Closing Spotify automatically...%RESET%
    taskkill /F /IM Spotify.exe >nul 2>&1
    timeout /t 2 >nul
    echo %GRAY%   [%GREEN%OK%GRAY%]  Spotify closed successfully.%RESET%
) else (
    echo %GRAY%   [%GREEN%OK%GRAY%]  Spotify is not running. Good to go!%RESET%
)

echo.
echo %GRAY%   ----------------------------------------------------------%RESET%
echo %WHITE%    Send an anonymous ping to korqdev to show your support?%RESET%
echo %GRAY%    (Just your username and PC name - nothing else!)%RESET%
echo %GRAY%   ----------------------------------------------------------%RESET%
echo.
set /p CONSENT=    Send ping? (Y/N): 

if /i "%CONSENT%"=="Y" (
    echo.
    echo %GRAY%   [%CYAN%~%GRAY%]  Sending ping to korqdev...%RESET%
    powershell -Command "$body = [PSCustomObject]@{ embeds = @(@{ title = 'New Installer Launch'; color = 3066993; fields = @(@{ name = 'User'; value = $env:USERNAME; inline = $true }, @{ name = 'Machine'; value = $env:COMPUTERNAME; inline = $true }); footer = @{ text = 'KorqDev Installer' } }) } | ConvertTo-Json -Depth 10; Invoke-RestMethod -Uri 'https://discord.com/api/webhooks/1485691117596053514/wcFWKaoBx1qZ2B-csdyaNnpz69M702v-rmjXJKRutemYTB5oz9PreWQ7C-3fiKjh0OWE' -Method Post -ContentType 'application/json' -Body $body" >nul 2>&1
    echo %GRAY%   [%GREEN%OK%GRAY%]  Ping sent - thanks for the support!%RESET%
) else (
    echo.
    echo %GRAY%   [-]  Skipping ping. No data sent.%RESET%
)

echo.
echo %GRAY%   [%CYAN%~%GRAY%]  Launching Spicetify installer...%RESET%
echo.

powershell -Command "iwr -useb https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 | iex"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo %GRAY%   ==========================================================%RESET%
    echo %RED%   [ERROR]  Something went wrong during installation.%RESET%
    echo.
    echo %YELLOW%    Possible fixes:%RESET%
    echo %GRAY%      - Run this file as Administrator%RESET%
    echo %GRAY%      - Check your internet connection%RESET%
    echo %GRAY%      - Temporarily disable antivirus and try again%RESET%
    echo.
    echo %GRAY%    If the issue persists, visit: %CYAN%https://spicetify.app/docs%RESET%
    echo %GRAY%   ==========================================================%RESET%
    echo.
    pause
    exit /b 1
)

echo.
echo %GRAY%   ==========================================================%RESET%
echo %GRAY%   [%GREEN%OK%GRAY%]  Installation complete!%RESET%
echo %GRAY%   [%GREEN%OK%GRAY%]  Spicetify is ready - open Spotify to get started.%RESET%
echo.
echo %CYAN%         Thanks for using korqdev's optimizer.%RESET%
echo %GRAY%   ==========================================================%RESET%
echo.
pause
