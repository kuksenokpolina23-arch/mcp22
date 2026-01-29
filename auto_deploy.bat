@echo off
chcp 65001 >nul
echo ================================================
echo Автоматическое развертывание MCP на сервере
echo ================================================
echo.
echo ВНИМАНИЕ: Этот скрипт создаст команды для сервера
echo.

set OUTPUT_FILE=server_commands.sh

echo Создаю файл с командами для сервера...
(
echo #!/bin/bash
echo # Auto-generated deployment script
echo set -e
echo.
echo echo "=== Step 1: Clone project ==="
echo cd /root
echo if [ -d "mcp22" ]; then
echo   echo "Directory exists, updating..."
echo   cd mcp22
echo   git pull origin main
echo else
echo   git clone https://github.com/kuksenokpolina23-arch/mcp22.git
echo   cd mcp22
echo fi
echo.
echo echo "=== Step 2: Install dependencies ==="
echo apt update
echo apt install -y python3-pip python3-venv
echo.
echo echo "=== Step 3: Install Python packages ==="
echo pip3 install --upgrade pip
echo pip3 install -r requirements.txt
echo.
echo echo "=== Step 4: Setup scripts ==="
echo chmod +x *.sh
echo.
echo echo "=== Step 5: Stop old server ==="
echo pkill -f mcp_sse_server.py ^|^| true
echo sleep 2
echo.
echo echo "=== Step 6: Start server ==="
echo cd /root/mcp22
echo python3 mcp_sse_server.py ^> mcp_server.log 2^>^&1 ^&
echo sleep 3
echo.
echo echo "=== Step 7: Check status ==="
echo ps aux ^| grep mcp_sse_server.py ^| grep -v grep
echo echo ""
echo netstat -tlnp ^| grep python ^|^| ss -tlnp ^| grep python
echo echo ""
echo tail -20 mcp_server.log
echo.
echo echo "=== Deployment Complete ==="
) > %OUTPUT_FILE%

echo.
echo ================================================
echo Файл создан: %OUTPUT_FILE%
echo ================================================
echo.
echo ИНСТРУКЦИЯ:
echo.
echo 1. На сервере (в SSH терминале) выполни:
echo    wget https://raw.githubusercontent.com/kuksenokpolina23-arch/mcp22/main/%OUTPUT_FILE%
echo    chmod +x %OUTPUT_FILE%
echo    ./%OUTPUT_FILE%
echo.
echo ИЛИ скопируй содержимое файла %OUTPUT_FILE%
echo и вставь по одной строке в SSH терминал
echo.
echo ================================================
echo.
echo Открыть файл сейчас?
pause

notepad %OUTPUT_FILE%
