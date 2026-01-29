#!/bin/bash

echo "=================================="
echo "WordPress MCP Server - Status Check"
echo "=================================="
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция проверки сервиса
check_service() {
    local name=$1
    local check_command=$2
    
    echo -n "Checking $name... "
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# Функция проверки HTTP endpoint
check_http() {
    local name=$1
    local url=$2
    
    echo -n "Checking $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ OK (HTTP $response)${NC}"
        return 0
    elif [ -n "$response" ]; then
        echo -e "${YELLOW}⚠ HTTP $response${NC}"
        return 1
    else
        echo -e "${RED}✗ No response${NC}"
        return 1
    fi
}

# 1. Проверка Python
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. System Requirements"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_service "Python3" "command -v python3"
if command -v python3 &> /dev/null; then
    echo "   Version: $(python3 --version)"
fi

check_service "pip3" "command -v pip3"
echo ""

# 2. Проверка файлов проекта
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Project Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_service "mcp_sse_server.py" "test -f mcp_sse_server.py"
check_service "requirements.txt" "test -f requirements.txt"
check_service "Virtual environment" "test -d venv"
echo ""

# 3. Проверка MCP сервера (systemd)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. MCP Server (systemd)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet wordpress-mcp-server 2>/dev/null; then
    echo -e "Status: ${GREEN}✓ Active${NC}"
    echo "Uptime: $(systemctl show wordpress-mcp-server -p ActiveEnterTimestamp --value)"
    echo "Main PID: $(systemctl show wordpress-mcp-server -p MainPID --value)"
else
    echo -e "Status: ${RED}✗ Inactive${NC}"
    echo "To start: sudo systemctl start wordpress-mcp-server"
fi
echo ""

# 4. Проверка MCP сервера (процесс)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. MCP Server (process)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if pgrep -f "mcp_sse_server.py" > /dev/null; then
    echo -e "Process: ${GREEN}✓ Running${NC}"
    echo "PIDs: $(pgrep -f 'mcp_sse_server.py' | tr '\n' ' ')"
    
    # Проверка порта
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "Port 8000: ${GREEN}✓ Listening${NC}"
    else
        echo -e "Port 8000: ${RED}✗ Not listening${NC}"
    fi
else
    echo -e "Process: ${RED}✗ Not running${NC}"
fi
echo ""

# 5. Проверка HTTP endpoints
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. HTTP Endpoints (Local)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_http "Health endpoint" "http://localhost:8000/health"
check_http "Root endpoint" "http://localhost:8000/"
check_http "SSE endpoint" "http://localhost:8000/sse"
echo ""

# 6. Проверка Cloudflare Tunnel
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Cloudflare Tunnel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_service "cloudflared binary" "command -v cloudflared"

if pgrep -f cloudflared > /dev/null; then
    echo -e "Process: ${GREEN}✓ Running${NC}"
    echo "PIDs: $(pgrep -f cloudflared | tr '\n' ' ')"
    
    # Поиск URL
    if [ -f ".tunnel_url" ]; then
        TUNNEL_URL=$(cat .tunnel_url)
        echo -e "URL: ${GREEN}$TUNNEL_URL${NC}"
    elif [ -f "/root/cloudflared.log" ]; then
        TUNNEL_URL=$(grep -o 'https://[^ ]*trycloudflare.com' /root/cloudflared.log | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo -e "URL: ${GREEN}$TUNNEL_URL${NC}"
        else
            echo -e "URL: ${YELLOW}⚠ Not found in logs${NC}"
        fi
    elif [ -f "cloudflared.log" ]; then
        TUNNEL_URL=$(grep -o 'https://[^ ]*trycloudflare.com' cloudflared.log | head -1)
        if [ -n "$TUNNEL_URL" ]; then
            echo -e "URL: ${GREEN}$TUNNEL_URL${NC}"
        fi
    fi
    
    # Проверка доступности tunnel URL
    if [ -n "$TUNNEL_URL" ]; then
        echo -n "Testing tunnel... "
        response=$(curl -s -o /dev/null -w "%{http_code}" "${TUNNEL_URL}/health" 2>/dev/null)
        if [ "$response" = "200" ]; then
            echo -e "${GREEN}✓ OK${NC}"
        else
            echo -e "${YELLOW}⚠ HTTP $response${NC}"
        fi
    fi
else
    echo -e "Process: ${RED}✗ Not running${NC}"
    echo "To start: ./restart_tunnel.sh"
fi
echo ""

# 7. Логи
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if systemctl is-active --quiet wordpress-mcp-server 2>/dev/null; then
    echo "Server logs: sudo journalctl -u wordpress-mcp-server -n 20"
fi
if [ -f "/root/cloudflared.log" ]; then
    echo "Tunnel logs: tail -f /root/cloudflared.log"
elif [ -f "cloudflared.log" ]; then
    echo "Tunnel logs: tail -f cloudflared.log"
fi
if [ -f "server.log" ]; then
    echo "Manual logs: tail -f server.log"
fi
echo ""

# 8. Итоговая оценка
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Overall Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ALL_OK=true

# Проверка основных компонентов
if ! pgrep -f "mcp_sse_server.py" > /dev/null; then
    echo -e "${RED}✗ MCP Server is not running${NC}"
    ALL_OK=false
fi

if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${RED}✗ MCP Server is not responding${NC}"
    ALL_OK=false
fi

if ! pgrep -f cloudflared > /dev/null; then
    echo -e "${YELLOW}⚠ Cloudflare Tunnel is not running${NC}"
    echo "  (This is OK for local testing)"
fi

if $ALL_OK; then
    echo -e "${GREEN}✅ All critical services are running!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Get tunnel URL: ./restart_tunnel.sh (if not running)"
    echo "  2. Add to ChatGPT: Settings → Connectors"
    echo "  3. Test: Ask ChatGPT to create a post"
else
    echo -e "${RED}❌ Some services are not working${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Start server: ./start_server.sh"
    echo "  2. Or systemd: sudo systemctl start wordpress-mcp-server"
    echo "  3. Check logs: sudo journalctl -u wordpress-mcp-server -f"
    echo "  4. Start tunnel: ./restart_tunnel.sh"
fi

echo ""
echo "=================================="
