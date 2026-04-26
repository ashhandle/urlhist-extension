@echo off
:: Usage: install.bat <EXTENSION_ID>
:: Registers the native messaging host for Chrome and Edge on Windows.

setlocal enabledelayedexpansion

if "%~1"=="" (
  echo Usage: install.bat ^<EXTENSION_ID^>
  echo   Find your Extension ID at chrome://extensions after loading the extension.
  exit /b 1
)

set EXTENSION_ID=%~1
set SCRIPT_DIR=%~dp0
set HOST_SCRIPT=%SCRIPT_DIR%native-host\urlhist_host.py
set HOST_NAME=com.urlhist.host

:: Verify Python is available
where python >nul 2>&1
if errorlevel 1 (
  echo Error: Python is required but not found in PATH.
  exit /b 1
)

:: Build the destination JSON path
set CHROME_HOSTS=%APPDATA%\Google\Chrome\NativeMessagingHosts
set EDGE_HOSTS=%APPDATA%\Microsoft\Edge\NativeMessagingHosts

:: Write resolved JSON for Chrome
if exist "%APPDATA%\Google\Chrome" (
  if not exist "%CHROME_HOSTS%" mkdir "%CHROME_HOSTS%"
  (
    echo {
    echo   "name": "com.urlhist.host",
    echo   "description": "Appends browsed URLs to URLHIST.txt in the OS temp directory.",
    echo   "path": "%HOST_SCRIPT:\=\\%",
    echo   "type": "stdio",
    echo   "allowed_origins": [
    echo     "chrome-extension://%EXTENSION_ID%/"
    echo   ]
    echo }
  ) > "%CHROME_HOSTS%\%HOST_NAME%.json"

  :: Register in Windows registry for Chrome
  reg add "HKCU\SOFTWARE\Google\Chrome\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%CHROME_HOSTS%\%HOST_NAME%.json" /f >nul
  echo [OK] Installed for Google Chrome
) else (
  echo [SKIP] Google Chrome not found
)

:: Write resolved JSON for Edge
if exist "%APPDATA%\Microsoft\Edge" (
  if not exist "%EDGE_HOSTS%" mkdir "%EDGE_HOSTS%"
  (
    echo {
    echo   "name": "com.urlhist.host",
    echo   "description": "Appends browsed URLs to URLHIST.txt in the OS temp directory.",
    echo   "path": "%HOST_SCRIPT:\=\\%",
    echo   "type": "stdio",
    echo   "allowed_origins": [
    echo     "chrome-extension://%EXTENSION_ID%/"
    echo   ]
    echo }
  ) > "%EDGE_HOSTS%\%HOST_NAME%.json"

  :: Register in Windows registry for Edge
  reg add "HKCU\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\%HOST_NAME%" /ve /t REG_SZ /d "%EDGE_HOSTS%\%HOST_NAME%.json" /f >nul
  echo [OK] Installed for Microsoft Edge
) else (
  echo [SKIP] Microsoft Edge not found
)

echo.
echo Done. Restart Chrome/Edge, then browse -- URLs will be appended to:
for /f "delims=" %%T in ('python -c "import tempfile; print(tempfile.gettempdir())"') do echo   %%T\URLHIST.txt

endlocal
