@echo off
echo ========================================
echo Connecting to MCP Server
echo ========================================
echo.
echo Server: 77.73.232.84
echo User: root
echo.
echo Enter password when prompted...
echo.

ssh root@77.73.232.84

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo Connection failed!
    echo ========================================
    echo.
    echo Possible issues:
    echo 1. SSH not installed - install Git for Windows
    echo 2. Wrong password
    echo 3. Server not responding
    echo 4. Firewall blocking connection
    echo.
)

pause
