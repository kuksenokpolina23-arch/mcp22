@echo off
echo ====================================
echo GitHub Push Script for MCP22 Project
echo ====================================
echo.

cd /d "f:\ПОЛИНА\ИЗВЕСТИЯ\mcp22"

echo Step 1: Checking git status...
git status
echo.

echo Step 2: Adding remote (if not exists)...
git remote -v
git remote add origin https://github.com/kuksenokpolina23-arch/mcp22.git 2>nul
echo.

echo Step 3: Setting up credential helper...
git config credential.helper store
echo.

echo Step 4: Pushing to GitHub...
echo You will be prompted for credentials:
echo Username: kuksenokpolina23-arch
echo Password: Use your GitHub token (YOUR_TOKEN_HERE)
echo.

git push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ====================================
    echo SUCCESS! Project pushed to GitHub!
    echo ====================================
    echo.
    echo Repository URL: https://github.com/kuksenokpolina23-arch/mcp22
    echo.
) else (
    echo ====================================
    echo ERROR: Push failed!
    echo ====================================
    echo.
    echo Try these solutions:
    echo 1. Make sure you're connected to internet
    echo 2. Check if repository exists on GitHub
    echo 3. Verify your GitHub token is valid
    echo.
)

pause
