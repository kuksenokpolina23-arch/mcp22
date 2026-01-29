@echo off
chcp 65001 >nul
echo ========================================
echo SSH Config Setup for MCP Server
echo ========================================
echo.

set SSH_DIR=%USERPROFILE%\.ssh
set CONFIG_FILE=%SSH_DIR%\config

echo Creating .ssh directory if needed...
if not exist "%SSH_DIR%" (
    mkdir "%SSH_DIR%"
    echo Created: %SSH_DIR%
) else (
    echo Directory exists: %SSH_DIR%
)
echo.

echo Checking existing config...
if exist "%CONFIG_FILE%" (
    echo Config file exists, checking for mcp-server entry...
    findstr /C:"Host mcp-server" "%CONFIG_FILE%" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo mcp-server entry already exists in config!
        echo.
        goto :connect
    )
)

echo Adding mcp-server configuration...
(
echo.
echo Host mcp-server
echo     HostName 77.73.232.84
echo     User root
echo     Port 22
echo     ServerAliveInterval 60
echo     ServerAliveCountMax 3
) >> "%CONFIG_FILE%"

echo.
echo ========================================
echo SSH Config Updated!
echo ========================================
echo.
echo Config file location: %CONFIG_FILE%
echo.

:connect
echo You can now connect using:
echo   Method 1: ssh mcp-server
echo   Method 2: ssh root@77.73.232.84
echo.
echo ========================================
echo.

choice /C YN /M "Do you want to connect now"
if %ERRORLEVEL% EQU 1 (
    echo.
    echo Connecting to server...
    echo.
    ssh root@77.73.232.84
)

echo.
pause
