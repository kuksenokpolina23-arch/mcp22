@echo off
chcp 65001 >nul
echo Initializing Git repository...

cd /d "%~dp0"

git init
if %errorlevel% neq 0 (
    echo Error: Failed to initialize git repository
    pause
    exit /b 1
)

git add .
if %errorlevel% neq 0 (
    echo Error: Failed to add files
    pause
    exit /b 1
)

git commit -m "Initial commit: WordPress MCP Server"
if %errorlevel% neq 0 (
    echo Error: Failed to create commit
    pause
    exit /b 1
)

echo.
echo Git repository initialized and files committed!
echo.
echo Now creating GitHub repository...
echo.

rem Check if gh CLI is installed
gh --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: GitHub CLI (gh) is not installed
    echo Please install it from: https://cli.github.com/
    pause
    exit /b 1
)

rem Create repository on GitHub
gh repo create wordpress-mcp-server --public --source=. --remote=origin --push

if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to create GitHub repository
    echo Please make sure you are logged in: gh auth login
    pause
    exit /b 1
)

echo.
echo Success! Repository created and pushed to GitHub!
echo.
pause
