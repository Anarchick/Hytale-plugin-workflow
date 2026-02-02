@echo off
setlocal enabledelayedexpansion

:: Move to the script's directory
cd /d "%~dp0"

set "LOCK_FILE=hytale-downloader.txt.lock"

echo ============================================
echo   Hytale Downloader - Update
echo ============================================
echo.

:: Check if HYTALE_DOWNLOADER_CLI is defined
if not defined HYTALE_DOWNLOADER_CLI (
    echo [ERROR] The HYTALE_DOWNLOADER_CLI environment variable is not defined.
    echo.
    echo Please define this variable with the full path to hytale-downloader.exe
    echo Example: C:\Tools\hytale-downloader\hytale-downloader.exe
    echo.
    pause
    exit /b 1
)

:: Check if the CLI exists
if not exist "%HYTALE_DOWNLOADER_CLI%" (
    echo [ERROR] The file %HYTALE_DOWNLOADER_CLI% does not exist.
    echo.
    echo Check that the path in the environment variable is correct.
    echo.
    pause
    exit /b 1
)

echo [OK] CLI found: %HYTALE_DOWNLOADER_CLI%
echo.

:: If .hytale-downloader-credentials.json is missing
if not exist ".hytale-downloader-credentials.json" (
    echo [ERROR] Credentials file not found: .hytale-downloader-credentials.json
    echo Please authenticate using the CLI before running this script.
    echo.
    "%HYTALE_DOWNLOADER_CLI%" -print-version
    pause
    exit /b 1
)

:: Get the latest available version
echo [INFO] Checking for the latest available version...
for /f "delims=" %%i in ('"%HYTALE_DOWNLOADER_CLI%" -print-version 2^>nul') do set LATEST_VERSION=%%i

if not defined LATEST_VERSION (
    echo [ERROR] Unable to retrieve version from hytale-downloader
    echo.
    pause
    exit /b 1
)

echo [INFO] Latest available version: %LATEST_VERSION%
echo.

:: Create the lock file if it doesn't exist
if not exist "%LOCK_FILE%" (
    echo [INFO] Creating %LOCK_FILE% file...
    echo version: unknown-%date:~-4,4%.%date:~-10,2%.%date:~-7,2% > "%LOCK_FILE%"
    echo download_date: %date% %time% >> "%LOCK_FILE%"
    set INSTALLED_VERSION=unknown
) else (
    :: Read the installed version
    for /f "tokens=2 delims=: " %%i in ('findstr "^version:" "%LOCK_FILE%"') do set INSTALLED_VERSION=%%i
)

if not defined INSTALLED_VERSION set INSTALLED_VERSION=unknown

echo [INFO] Installed version: %INSTALLED_VERSION%
echo.

:: Check if the version is already installed
if "%INSTALLED_VERSION%"=="%LATEST_VERSION%" (
    echo [INFO] Version %LATEST_VERSION% is already installed.
    echo No update necessary.
    echo.
    pause
    exit /b 0
)

:: Download via CLI
echo [INFO] Downloading version %LATEST_VERSION%...
echo.

:: Move to the CLI directory for download
for %%i in ("%HYTALE_DOWNLOADER_CLI%") do set "CLI_DIR=%%~dpi"
pushd "%CLI_DIR%"
"%HYTALE_DOWNLOADER_CLI%"
set DOWNLOAD_STATUS=%ERRORLEVEL%
popd

if %DOWNLOAD_STATUS% neq 0 (
    echo [ERROR] Download failed.
    echo.
    pause
    exit /b 1
)

echo.
echo [INFO] Download completed.
echo.

:: Search for the latest downloaded .zip file
echo [INFO] Searching for downloaded zip file...
set "DOWNLOADED_ZIP="
for /f "delims=" %%i in ('dir /b /od /a-d "%CLI_DIR%*.zip" 2^>nul') do set DOWNLOADED_ZIP=%%i

if not defined DOWNLOADED_ZIP (
    echo [ERROR] No .zip file found in %CLI_DIR%
    echo.
    pause
    exit /b 1
)

echo [INFO] File found: %DOWNLOADED_ZIP%
echo.

:: Ask if we should backup existing files
set /p BACKUP="Backup existing files? (Y/N): "
if /i "%BACKUP%"=="Y" (
    echo.
    echo [INFO] Backing up existing files...

    :: Rename Assets.zip
    if exist "Assets.zip" (
        echo [INFO] Renaming Assets.zip to Assets-%INSTALLED_VERSION%.zip
        ren "Assets.zip" "Assets-%INSTALLED_VERSION%.zip"
    )

    :: Compress server/Server/
    if exist "server\Server" (
        echo [INFO] Compressing server/Server to server/Server-%INSTALLED_VERSION%.zip
        powershell -command "$ErrorActionPreference='Stop'; try { Compress-Archive -Path 'server\Server\*' -DestinationPath 'server\Server-%INSTALLED_VERSION%.zip' -Force; exit 0 } catch { Write-Host '[ERROR]' $_.Exception.Message; exit 1 }"
        if !ERRORLEVEL! neq 0 (
            echo [WARNING] Failed to compress server backup. Continuing anyway...
        )
    )
    echo.
)

:: Create necessary directories
if not exist "server" mkdir "server"
if not exist "server\Server" mkdir "server\Server"

:: Extract the downloaded zip temporarily
echo [INFO] Extracting files...
set "TEMP_EXTRACT=%TEMP%\hytale_extract_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TEMP_EXTRACT=%TEMP_EXTRACT: =0%"
mkdir "%TEMP_EXTRACT%"

powershell -command "$ErrorActionPreference='Stop'; try { Expand-Archive -Path '%CLI_DIR%%DOWNLOADED_ZIP%' -DestinationPath '%TEMP_EXTRACT%' -Force; exit 0 } catch { Write-Host '[ERROR]' $_.Exception.Message; exit 1 }"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to extract the ZIP file.
    rd /s /q "%TEMP_EXTRACT%" 2>nul
    pause
    exit /b 1
)

:: Validate ZIP structure
echo [INFO] Validating ZIP structure...
set "STRUCTURE_VALID=1"
if not exist "%TEMP_EXTRACT%\Assets.zip" (
    echo [WARNING] Assets.zip not found in the archive.
    set "STRUCTURE_VALID=0"
)
if not exist "%TEMP_EXTRACT%\Server" (
    echo [WARNING] Server directory not found in the archive.
    set "STRUCTURE_VALID=0"
)

if "%STRUCTURE_VALID%"=="0" (
    echo.
    echo [ERROR] The ZIP file structure appears to be invalid.
    echo Hytale has probably changed the ZIP structure.
    echo Please check the downloaded file manually: %CLI_DIR%%DOWNLOADED_ZIP%
    echo.
    echo Installation aborted.
    rd /s /q "%TEMP_EXTRACT%"
    pause
    exit /b 1
)

echo [INFO] ZIP structure validated successfully.
echo.

:: Copy Assets.zip
if exist "%TEMP_EXTRACT%\Assets.zip" (
    echo [INFO] Copying Assets.zip...
    copy /y "%TEMP_EXTRACT%\Assets.zip" "Assets.zip" >nul
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to copy Assets.zip
        echo Installation failed. Please restore backups if needed.
        rd /s /q "%TEMP_EXTRACT%"
        pause
        exit /b 1
    )
)

:: Copy Server/ content
if exist "%TEMP_EXTRACT%\Server" (
    echo [INFO] Copying server files...
    xcopy /y /e /i "%TEMP_EXTRACT%\Server\*" "server\Server\" >nul
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to copy server files
        echo Installation failed. Please restore backups if needed.
        rd /s /q "%TEMP_EXTRACT%"
        pause
        exit /b 1
    )
)

echo [INFO] All files copied successfully.
echo.

:: Clean up temporary directory
rd /s /q "%TEMP_EXTRACT%"

:: Update the lock file
echo [INFO] Updating %LOCK_FILE% file...
echo # This file is used to track the installed version of Hytale-downloader. > "%LOCK_FILE%"
echo version: %LATEST_VERSION% >> "%LOCK_FILE%"
echo download_date: %date% %time% >> "%LOCK_FILE%"

echo.
echo ============================================
echo   Update completed!
echo ============================================
echo Installed version: %LATEST_VERSION%
echo Remember to regularly clean the old .zip files located in %CLI_DIR%
echo You should also clean up any Assets-*.zip and server/Server-*.zip backup files if no longer needed.
echo.
pause
