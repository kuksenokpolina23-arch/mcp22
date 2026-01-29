#!/bin/bash

echo "=================================="
echo "WordPress MCP Server - Manual Start"
echo "=================================="

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python3 not found!"
    echo "Please install Python3 first: sudo apt install python3"
    exit 1
fi

# Проверка наличия виртуального окружения
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Активация виртуального окружения
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Проверка и установка зависимостей
if [ ! -f "venv/bin/uvicorn" ]; then
    echo "📦 Installing dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "✓ Dependencies installed"
fi

# Проверка наличия основного файла
if [ ! -f "mcp_sse_server.py" ]; then
    echo "❌ Error: mcp_sse_server.py not found!"
    exit 1
fi

# Проверка конфигурации
echo "🔍 Checking configuration..."
if grep -q "your-wordpress-site.com" mcp_sse_server.py; then
    echo "⚠️  WARNING: WordPress credentials not configured!"
    echo "Please edit mcp_sse_server.py and set:"
    echo "  - WORDPRESS_URL"
    echo "  - WORDPRESS_USERNAME"
    echo "  - WORDPRESS_PASSWORD"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Проверка порта
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 8000 is already in use!"
    echo "Killing existing process..."
    lsof -ti:8000 | xargs kill -9
    sleep 2
fi

# Запуск сервера
echo ""
echo "=================================="
echo "🚀 Starting WordPress MCP Server..."
echo "=================================="
echo ""
echo "Server will be available at:"
echo "  - Local: http://localhost:8000"
echo "  - Health: http://localhost:8000/health"
echo "  - SSE: http://localhost:8000/sse"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "=================================="
echo ""

# Запуск с логированием
python3 mcp_sse_server.py 2>&1 | tee -a server.log
