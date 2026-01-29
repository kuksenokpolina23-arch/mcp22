#!/bin/bash

echo "=================================="
echo "Cloudflare Tunnel - Restart"
echo "=================================="

# Функция для поиска URL в логах
get_tunnel_url() {
    if [ -f "$1" ]; then
        grep -o 'https://[^ ]*trycloudflare.com' "$1" | head -1
    fi
}

# Остановка существующих туннелей
echo "🛑 Stopping existing Cloudflare tunnels..."
pkill -f cloudflared
sleep 2

# Проверка, убит ли процесс
if pgrep -f cloudflared > /dev/null; then
    echo "⚠️  Force killing cloudflared processes..."
    pkill -9 -f cloudflared
    sleep 1
fi

echo "✓ All cloudflared processes stopped"

# Проверка установки cloudflared
if ! command -v cloudflared &> /dev/null; then
    echo "❌ Error: cloudflared not found!"
    echo ""
    echo "Installing Cloudflare Tunnel..."
    cd ~
    
    # Определение архитектуры
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        BINARY="cloudflared-linux-amd64"
    elif [ "$ARCH" = "aarch64" ]; then
        BINARY="cloudflared-linux-arm64"
    else
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
    fi
    
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/$BINARY
    chmod +x $BINARY
    sudo mv $BINARY /usr/local/bin/cloudflared
    
    echo "✓ Cloudflared installed"
fi

# Проверка, запущен ли MCP сервер
echo ""
echo "🔍 Checking if MCP server is running..."
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "⚠️  WARNING: MCP server is not running on port 8000!"
    echo ""
    echo "Please start the MCP server first:"
    echo "  ./start_server.sh"
    echo "  or"
    echo "  sudo systemctl start wordpress-mcp-server"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ MCP server is running"
fi

# Выбор расположения лог-файла
LOG_FILE="cloudflared.log"
if [ -w "/root" ]; then
    LOG_FILE="/root/cloudflared.log"
elif [ -w "$HOME" ]; then
    LOG_FILE="$HOME/cloudflared.log"
fi

# Удаление старого лога
rm -f "$LOG_FILE"

# Запуск нового туннеля
echo ""
echo "=================================="
echo "🚀 Starting new Cloudflare Tunnel..."
echo "=================================="
echo ""

nohup cloudflared tunnel --url http://localhost:8000 > "$LOG_FILE" 2>&1 &
TUNNEL_PID=$!

echo "✓ Tunnel started with PID: $TUNNEL_PID"
echo "📝 Logs: $LOG_FILE"
echo ""
echo "⏳ Waiting for tunnel URL (this may take 5-10 seconds)..."

# Ожидание появления URL в логах
MAX_WAIT=15
COUNTER=0
TUNNEL_URL=""

while [ $COUNTER -lt $MAX_WAIT ]; do
    sleep 1
    COUNTER=$((COUNTER+1))
    
    TUNNEL_URL=$(get_tunnel_url "$LOG_FILE")
    
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
    
    echo -n "."
done

echo ""
echo ""

# Вывод результата
if [ -n "$TUNNEL_URL" ]; then
    echo "=================================="
    echo "✅ TUNNEL READY!"
    echo "=================================="
    echo ""
    echo "🌐 Your HTTPS URL:"
    echo "   $TUNNEL_URL"
    echo ""
    echo "📱 For ChatGPT use:"
    echo "   ${TUNNEL_URL}/sse"
    echo ""
    echo "🧪 Test it:"
    echo "   curl ${TUNNEL_URL}/health"
    echo ""
    echo "📝 View logs:"
    echo "   tail -f $LOG_FILE"
    echo ""
    echo "🛑 Stop tunnel:"
    echo "   pkill cloudflared"
    echo ""
    echo "=================================="
else
    echo "=================================="
    echo "⚠️  WARNING: Could not get tunnel URL"
    echo "=================================="
    echo ""
    echo "Check the logs manually:"
    echo "  cat $LOG_FILE | grep https://"
    echo ""
    echo "Or wait a few more seconds and run:"
    echo "  cat $LOG_FILE"
    echo ""
fi

# Сохранение URL в файл для других скриптов
if [ -n "$TUNNEL_URL" ]; then
    echo "$TUNNEL_URL" > .tunnel_url
fi
