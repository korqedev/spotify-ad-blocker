@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ==========================================================
::  KORQDEV Spotify Optimization + Spicetify Installer
::  v1.4.0 - animated progress, countdowns, timer, summary
:: ==========================================================

set "VERSION=1.4.0"
set "LOGDIR=%TEMP%\KorqDev"
set "LOGFILE=%LOGDIR%\spotify_optimizer_%DATE:/=-%_%TIME::=-%.log"
set "LOGFILE=%LOGFILE: =_%"
set "DEBUG=0"
set "STEP_DELAY=4"
set "TOTAL_STEPS=5"

set "FAILED_CODE=0"
set "FAILED_STEP=None"
set "SUMMARY_INTERNET=PENDING"
set "SUMMARY_POWERSHELL=PENDING"
set "SUMMARY_SPOTIFY=PENDING"
set "SUMMARY_SPICETIFY=PENDING"
set "SUMMARY_LAUNCH=PENDING"

if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1

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

:: Get Windows version
for /f "tokens=4-5 delims=. " %%a in ('ver') do set "WINVER=%%a.%%b"
for /f "tokens=3 delims=[ " %%a in ('ver') do set "WINBUILD=%%a"

:: Runtime start, uses PowerShell because it is already required later.
for /f %%A in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()" 2^>nul') do set "SCRIPT_START_EPOCH=%%A"
if not defined SCRIPT_START_EPOCH set "SCRIPT_START_EPOCH=0"

color 00
cls

call :Log "=========================================================="
call :Log "KorqDev Spotify Optimizer v%VERSION%"
call :Log "Started: %DATE% %TIME%"
call :Log "User: %USERNAME%"
call :Log "Machine: %COMPUTERNAME%"
call :Log "Script: %~f0"
call :Log "=========================================================="

call :BootAnimation
call :Header

:: ---- ADMIN CHECK / AUTO-ELEVATE ----
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    call :Warn "Administrator access required. Relaunching with elevation..."
    call :Log "Not elevated. Attempting UAC relaunch."
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        set "FAILED_CODE=100"
        set "FAILED_STEP=Admin elevation"
        call :Fail "Could not relaunch as Administrator. Right-click and run as Administrator."
        pause
        exit /b 1
    )
    exit /b
) else (
    call :Ok "Running as Administrator."
)

echo.
echo %GRAY%   Log file:%RESET% %CYAN%%LOGFILE%%RESET%
echo.

call :Stage 1 %TOTAL_STEPS% "Checking internet connection"
call :CheckInternet || (
    set "FAILED_CODE=101"
    set "FAILED_STEP=Internet connection"
    set "SUMMARY_INTERNET=FAILED"
    goto :ErrorExit
)
set "SUMMARY_INTERNET=OK"
call :StepDone "Internet connection checked" 1 %TOTAL_STEPS%

call :Stage 2 %TOTAL_STEPS% "Checking PowerShell availability"
where powershell >nul 2>&1
if errorlevel 1 (
    set "FAILED_CODE=102"
    set "FAILED_STEP=PowerShell availability"
    set "SUMMARY_POWERSHELL=FAILED"
    call :Fail "PowerShell was not found. This installer needs PowerShell."
    goto :ErrorExit
)
set "SUMMARY_POWERSHELL=OK"
call :Ok "PowerShell is available."
call :Log "PowerShell check passed."
call :StepDone "PowerShell availability checked" 2 %TOTAL_STEPS%

call :Stage 3 %TOTAL_STEPS% "Closing Spotify if it is running"
tasklist /FI "IMAGENAME eq Spotify.exe" 2>nul | find /I "Spotify.exe" >nul
if !ERRORLEVEL!==0 (
    call :Warn "Spotify is currently open. Closing it now..."
    taskkill /F /IM Spotify.exe >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        set "FAILED_CODE=103"
        set "FAILED_STEP=Closing Spotify"
        set "SUMMARY_SPOTIFY=FAILED"
        call :Fail "Could not close Spotify. Close it manually and run this again."
        goto :ErrorExit
    )
    timeout /t 2 /nobreak >nul
    call :Ok "Spotify closed."
) else (
    call :Ok "Spotify is not running."
)
set "SUMMARY_SPOTIFY=OK"
call :StepDone "Spotify process handled" 3 %TOTAL_STEPS%

call :Stage 4 %TOTAL_STEPS% "Installing latest Spicetify CLI"
call :Log "Starting Spicetify installer."
call :Working "Preparing installer command" 3
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iwr -useb 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1' | iex; exit $LASTEXITCODE } catch { Write-Error $_; exit 1 }" >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    set "FAILED_CODE=104"
    set "FAILED_STEP=Spicetify install"
    set "SUMMARY_SPICETIFY=FAILED"
    call :Fail "Spicetify installation failed."
    goto :ErrorExit
)
set "SUMMARY_SPICETIFY=OK"
call :Ok "Spicetify installer finished."
call :StepDone "Spicetify installation checked" 4 %TOTAL_STEPS%

call :Stage 5 %TOTAL_STEPS% "Launching Spotify"
set "SPOTIFY_EXE=%APPDATA%\Spotify\Spotify.exe"
if exist "%SPOTIFY_EXE%" (
    start "" "%SPOTIFY_EXE%"
    set "SUMMARY_LAUNCH=OK"
    call :Ok "Spotify launched."
    call :Log "Spotify launched from %SPOTIFY_EXE%."
) else (
    set "SUMMARY_LAUNCH=WARNING"
    call :Warn "Spotify.exe was not found at the usual path."
    call :Log "Spotify not found at %SPOTIFY_EXE%."
)
call :StepDone "Launch step completed" 5 %TOTAL_STEPS%

goto :Success

:BootAnimation
cls
echo.
echo %CYAN%   Initializing KorqDev installer...%RESET%
timeout /t 1 /nobreak >nul
echo %GRAY%   Loading checks and logging modules...%RESET%
timeout /t 1 /nobreak >nul
echo %GRAY%   Preparing clean step screens...%RESET%
timeout /t 1 /nobreak >nul
cls
exit /b

:Header
echo.
echo.
echo %CYAN%   ##  ##   ####   ## ##    ####   #####   #####   #####   ##  ##%RESET%
echo %CYAN%   ## ##   ##  ##  ####    ##  ##  ##      ##  ##  ##      ##  ##%RESET%
echo %CYAN%   ####    ##  ##  ###     ##  ##  #####   ##  ##  #####    ####%RESET%
echo %CYAN%   ## ##   ##  ##  ## ##   #####   ##      ##  ##  ##        ##%RESET%
echo %CYAN%   ##  ##   ####   ##  ##     ##   #####   #####   #####     ##%RESET%
echo.
echo %GRAY%   ==========================================================%RESET%
echo %BOLD%%WHITE%    SPOTIFY OPTIMIZATION + SPICETIFY INSTALLER  %GRAY%// KORQDEV%RESET%
echo %GRAY%    Version: %CYAN%%VERSION%%RESET%
echo %GRAY%   ==========================================================%RESET%
echo %GRAY%    User: %CYAN%%USERNAME%  %GRAY%^|  Machine: %CYAN%%COMPUTERNAME%%RESET%
echo %GRAY%    OS:   %CYAN%Windows %WINVER%  %GRAY%^|  Build:   %CYAN%%WINBUILD%%RESET%
echo %GRAY%   ==========================================================%RESET%
echo.
exit /b

:Stage
cls
call :Header
echo %GRAY%   Current log:%RESET% %CYAN%%LOGFILE%%RESET%
echo.
echo %GRAY%   [%CYAN%%~1/%~2%GRAY%]  %BOLD%%WHITE%%~3%RESET%
call :ShowTimer
call :ProgressBar %~1 %~2
echo.
call :Log "STEP %~1/%~2: %~3"
call :Countdown %STEP_DELAY% "%~3"
cls
call :Header
echo %GRAY%   Current log:%RESET% %CYAN%%LOGFILE%%RESET%
echo.
echo %GRAY%   [%CYAN%%~1/%~2%GRAY%]  %BOLD%%WHITE%%~3%RESET%
call :ShowTimer
call :ProgressBar %~1 %~2
echo.
exit /b

:Countdown
set "SECONDS_LEFT=%~1"
:CountdownLoop
if !SECONDS_LEFT! LEQ 0 exit /b
cls
call :Header
echo %GRAY%   Current log:%RESET% %CYAN%%LOGFILE%%RESET%
echo.
echo %GRAY%   Preparing:%RESET% %BOLD%%WHITE%%~2%RESET%
call :ShowTimer
echo %GRAY%   Starting in %CYAN%!SECONDS_LEFT!%GRAY% second(s)...%RESET%
echo %GRAY%   Please keep this window open.%RESET%
timeout /t 1 /nobreak >nul
set /a SECONDS_LEFT-=1
goto :CountdownLoop

:StepDone
echo.
call :Ok "%~1"
call :ShowTimer
if not "%~2"=="" call :ProgressBar %~2 %~3
echo.
echo %GRAY%   Moving to the next screen...%RESET%
timeout /t 2 /nobreak >nul
exit /b

:ProgressBar
set "CUR=%~1"
set "MAX=%~2"
set /a PCT=(CUR*100)/MAX
set /a FILLED=PCT/5
set "BAR="
for /L %%B in (1,1,20) do (
    if %%B LEQ !FILLED! (
        set "BAR=!BAR!#"
    ) else (
        set "BAR=!BAR!-"
    )
)
echo %GRAY%   Progress:%RESET% %CYAN%[!BAR!] !PCT!%%%RESET%
exit /b

:Working
set "WORK_TEXT=%~1"
set "WORK_LOOPS=%~2"
if "%WORK_LOOPS%"=="" set "WORK_LOOPS=3"
for /L %%S in (1,1,%WORK_LOOPS%) do (
    cls
    call :Header
    echo %GRAY%   %WORK_TEXT% %CYAN%[|]%RESET%
    call :ShowTimer
    timeout /t 1 /nobreak >nul
    cls
    call :Header
    echo %GRAY%   %WORK_TEXT% %CYAN%[/]%RESET%
    call :ShowTimer
    timeout /t 1 /nobreak >nul
    cls
    call :Header
    echo %GRAY%   %WORK_TEXT% %CYAN%[-]%RESET%
    call :ShowTimer
    timeout /t 1 /nobreak >nul
    cls
    call :Header
    echo %GRAY%   %WORK_TEXT% %CYAN%[\]%RESET%
    call :ShowTimer
    timeout /t 1 /nobreak >nul
)
exit /b

:ShowTimer
if "%SCRIPT_START_EPOCH%"=="0" (
    set "EL_MIN=0"
    set "EL_SEC_PAD=00"
    echo %GRAY%   Runtime:%RESET% %CYAN%0:00%RESET%
    exit /b
)
for /f %%A in ('powershell -NoProfile -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()" 2^>nul') do set "NOW_EPOCH=%%A"
set /a ELAPSED=NOW_EPOCH-SCRIPT_START_EPOCH
set /a EL_MIN=ELAPSED/60
set /a EL_SEC=ELAPSED%%60
if !EL_SEC! LSS 10 (set "EL_SEC_PAD=0!EL_SEC!") else (set "EL_SEC_PAD=!EL_SEC!")
echo %GRAY%   Runtime:%RESET% %CYAN%!EL_MIN!:!EL_SEC_PAD!%RESET%
exit /b

:Ok
echo %GRAY%   [%GREEN%OK%GRAY%]  %~1%RESET%
call :Log "OK: %~1"
exit /b

:Warn
echo %GRAY%   [%YELLOW%!%GRAY%]  %YELLOW%%~1%RESET%
call :Log "WARN: %~1"
exit /b

:Fail
echo %GRAY%   [%RED%ERROR%GRAY%]  %RED%%~1%RESET%
call :Log "ERROR: %~1"
exit /b

:Log
echo [%DATE% %TIME%] %~1>> "%LOGFILE%"
exit /b

:CheckInternet
ping github.com -n 1 >nul 2>&1
if errorlevel 1 (
    call :Fail "No internet connection detected, or GitHub is unreachable."
    exit /b 1
)
call :Ok "Internet connection looks good."
call :Log "Internet check passed."
exit /b 0

:SummaryLine
set "LABEL=%~1"
set "STATUS=%~2"
if /I "%STATUS%"=="OK" (
    echo %GRAY%   [%GREEN%OK%GRAY%]       %LABEL%%RESET%
) else if /I "%STATUS%"=="WARNING" (
    echo %GRAY%   [%YELLOW%WARN%GRAY%]     %LABEL%%RESET%
) else if /I "%STATUS%"=="FAILED" (
    echo %GRAY%   [%RED%FAILED%GRAY%]   %LABEL%%RESET%
) else (
    echo %GRAY%   [%YELLOW%PENDING%GRAY%]  %LABEL%%RESET%
)
exit /b

:ErrorExit
cls
call :Header
call :ShowTimer
echo.
echo %GRAY%   ==========================================================%RESET%
echo %RED%   Installation stopped.%RESET%
echo %GRAY%   Error code:%RESET% %RED%%FAILED_CODE%%RESET%
echo %GRAY%   Failed step:%RESET% %YELLOW%%FAILED_STEP%%RESET%
echo %GRAY%   ----------------------------------------------------------%RESET%
echo %YELLOW%   Check the log for details:%RESET%
echo %CYAN%   %LOGFILE%%RESET%
echo.
echo %YELLOW%   Common fixes:%RESET%
echo %GRAY%     - Re-run as Administrator%RESET%
echo %GRAY%     - Check your internet connection%RESET%
echo %GRAY%     - Close Spotify manually and try again%RESET%
echo %GRAY%     - Visit: %CYAN%https://spicetify.app/docs%RESET%
echo %GRAY%   ==========================================================%RESET%
call :Log "Finished with errors. Code: %FAILED_CODE%. Step: %FAILED_STEP%"
echo.
echo %GRAY%   Opening log in Notepad...%RESET%
start "" notepad "%LOGFILE%" >nul 2>&1
pause
exit /b 1

:Success
cls
call :Header
call :ShowTimer
call :ProgressBar %TOTAL_STEPS% %TOTAL_STEPS%
call :Log "Completed successfully."
echo.
echo %GRAY%   ==========================================================%RESET%
echo %GREEN%   INSTALL COMPLETE%RESET%
echo %GRAY%   ----------------------------------------------------------%RESET%
echo %GRAY%   Installation Summary%RESET%
echo %GRAY%   ----------------------------------------------------------%RESET%
call :SummaryLine "Internet Check" "%SUMMARY_INTERNET%"
call :SummaryLine "PowerShell Check" "%SUMMARY_POWERSHELL%"
call :SummaryLine "Spotify Closed" "%SUMMARY_SPOTIFY%"
call :SummaryLine "Spicetify Install" "%SUMMARY_SPICETIFY%"
call :SummaryLine "Spotify Launch" "%SUMMARY_LAUNCH%"
echo %GRAY%   ----------------------------------------------------------%RESET%
echo %GRAY%   Final runtime:%RESET% %CYAN%!EL_MIN!:!EL_SEC_PAD!%RESET%
echo %GRAY%   Log file:%RESET% %CYAN%%LOGFILE%%RESET%
echo.
echo %CYAN%   Thanks for using korqdev's optimizer.%RESET%
echo %GRAY%   ==========================================================%RESET%
echo.
pause
exit /b 0
