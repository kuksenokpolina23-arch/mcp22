@echo off
chcp 65001 >nul
echo ========================================
echo GitHub Push - Simple Version
echo ========================================
echo.

rem Navigate to project directory
f:
cd "\ПОЛИНА\ИЗВЕСТИЯ\mcp22"

echo Checking git repository...
git status >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Initializing git repository...
    git init
    git config user.name "kuksenokpolina23-arch"
    git config user.email "kuksenokpolina23-arch@users.noreply.github.com"
    git add .
    git commit -m "Initial commit: MCP SSE Server project"
    echo.
)

echo Checking remote...
git remote -v | findstr origin >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Adding remote with authentication...
    git remote add origin https://kuksenokpolina23-arch:YOUR_TOKEN_HERE@github.com/kuksenokpolina23-arch/mcp22.git
) else (
    echo Remote already exists, updating URL...
    git remote set-url origin https://kuksenokpolina23-arch:YOUR_TOKEN_HERE@github.com/kuksenokpolina23-arch/mcp22.git
)

echo.
echo Pushing to GitHub...
echo ========================================
git push -u origin main 2>&1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo SUCCESS! Project uploaded to GitHub!
    echo ========================================
    echo.
    echo View your repository at:
    echo https://github.com/kuksenokpolina23-arch/mcp22
    echo.
) else (
    echo.
    echo ========================================
    echo Push completed with warnings or errors
    echo ========================================
    echo Check the output above for details.
    echo.
)

pause
