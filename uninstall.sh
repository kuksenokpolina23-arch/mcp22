#!/bin/bash

echo "=================================="
echo "WordPress MCP Server - UNINSTALL"
echo "=================================="
echo ""
echo "⚠️  WARNING: This will completely remove:"
echo "  - MCP Server systemd service"
echo "  - Cloudflare Tunnel processes"
echo "  - Project directory (/opt/wordpress-mcp-server)"
echo "  - All logs and data"
echo ""
read -p "Are you sure you want to continue? (yes/NO): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo "Starting uninstall process..."
echo ""

# 1. Остановка и удаление systemd сервиса
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Removing systemd service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if systemctl is-active --quiet wordpress-mcp-server 2>/dev/null; then
    echo "Stopping wordpress-mcp-server service..."
    sudo systemctl stop wordpress-mcp-server
    echo "✓ Service stopped"
fi

if systemctl is-enabled --quiet wordpress-mcp-server 2>/dev/null; then
    echo "Disabling wordpress-mcp-server service..."
    sudo systemctl disable wordpress-mcp-server
    echo "✓ Service disabled"
fi

if [ -f "/etc/systemd/system/wordpress-mcp-server.service" ]; then
    echo "Removing service file..."
    sudo rm /etc/systemd/system/wordpress-mcp-server.service
    echo "✓ Service file removed"
fi

sudo systemctl daemon-reload
echo "✓ Systemd reloaded"
echo ""

# 2. Остановка процессов
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Stopping processes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Остановка MCP сервера
if pgrep -f "mcp_sse_server.py" > /dev/null; then
    echo "Killing MCP server processes..."
    pkill -f "mcp_sse_server.py"
    sleep 1
    
    if pgrep -f "mcp_sse_server.py" > /dev/null; then
        echo "Force killing..."
        pkill -9 -f "mcp_sse_server.py"
    fi
    echo "✓ MCP server stopped"
else
    echo "✓ MCP server was not running"
fi

# Остановка Cloudflare Tunnel
if pgrep -f cloudflared > /dev/null; then
    echo "Killing Cloudflare Tunnel processes..."
    pkill -f cloudflared
    sleep 1
    
    if pgrep -f cloudflared > /dev/null; then
        echo "Force killing..."
        pkill -9 -f cloudflared
    fi
    echo "✓ Cloudflare Tunnel stopped"
else
    echo "✓ Cloudflare Tunnel was not running"
fi

echo ""

# 3. Удаление проекта из /opt
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Removing project directory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "/opt/wordpress-mcp-server" ]; then
    echo "Removing /opt/wordpress-mcp-server..."
    sudo rm -rf /opt/wordpress-mcp-server
    echo "✓ Project directory removed"
else
    echo "✓ Project directory not found"
fi

echo ""

# 4. Удаление логов
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Removing logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cloudflare logs
if [ -f "/root/cloudflared.log" ]; then
    echo "Removing /root/cloudflared.log..."
    sudo rm /root/cloudflared.log
    echo "✓ Cloudflare log removed"
fi

if [ -f "$HOME/cloudflared.log" ]; then
    echo "Removing $HOME/cloudflared.log..."
    rm $HOME/cloudflared.log
    echo "✓ Cloudflare log removed"
fi

# Проверка текущей директории
if [ -f "cloudflared.log" ]; then
    read -p "Remove cloudflared.log in current directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm cloudflared.log
        echo "✓ Removed"
    fi
fi

if [ -f "server.log" ]; then
    read -p "Remove server.log in current directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm server.log
        echo "✓ Removed"
    fi
fi

echo ""

# 5. Опционально: удаление cloudflared binary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Cloudflare Tunnel binary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v cloudflared &> /dev/null; then
    read -p "Remove cloudflared binary? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CLOUDFLARED_PATH=$(which cloudflared)
        sudo rm "$CLOUDFLARED_PATH"
        echo "✓ Cloudflared binary removed from $CLOUDFLARED_PATH"
    else
        echo "✓ Cloudflared binary kept (can be used for other projects)"
    fi
else
    echo "✓ Cloudflared binary not found"
fi

echo ""

# 6. Firewall rules
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Firewall rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v ufw &> /dev/null; then
    read -p "Remove firewall rule for port 8000? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ufw delete allow 8000/tcp 2>/dev/null
        echo "✓ Firewall rule removed"
    else
        echo "✓ Firewall rule kept"
    fi
else
    echo "✓ UFW not installed"
fi

echo ""

# 7. Python packages (опционально)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Python packages"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Note: Python packages in /opt/wordpress-mcp-server/venv were removed."
echo "Global Python packages were NOT removed (they may be used by other projects)."
echo ""

# 8. Проверка остатков
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUES=0

if systemctl list-units --full --all | grep -q wordpress-mcp-server; then
    echo "⚠ systemd service still listed"
    ISSUES=$((ISSUES+1))
else
    echo "✓ systemd service removed"
fi

if pgrep -f "mcp_sse_server.py" > /dev/null; then
    echo "⚠ MCP server process still running"
    ISSUES=$((ISSUES+1))
else
    echo "✓ No MCP server processes"
fi

if pgrep -f cloudflared > /dev/null; then
    echo "⚠ Cloudflare Tunnel still running"
    ISSUES=$((ISSUES+1))
else
    echo "✓ No Cloudflare Tunnel processes"
fi

if [ -d "/opt/wordpress-mcp-server" ]; then
    echo "⚠ Project directory still exists"
    ISSUES=$((ISSUES+1))
else
    echo "✓ Project directory removed"
fi

echo ""

# Итог
echo "=================================="
if [ $ISSUES -eq 0 ]; then
    echo "✅ UNINSTALL COMPLETE!"
    echo ""
    echo "WordPress MCP Server has been completely removed."
    echo ""
    echo "What was removed:"
    echo "  ✓ systemd service"
    echo "  ✓ All processes stopped"
    echo "  ✓ Project directory (/opt/wordpress-mcp-server)"
    echo "  ✓ Service configuration"
    echo ""
    echo "What was kept (if exists):"
    echo "  • Python3 and pip3"
    echo "  • cloudflared binary (optional)"
    echo "  • Global Python packages"
    echo ""
    echo "To reinstall, run: ./install.sh"
else
    echo "⚠️  UNINSTALL COMPLETED WITH WARNINGS"
    echo ""
    echo "There were $ISSUES issue(s) during uninstall."
    echo "Please review the messages above."
    echo ""
    echo "You may need to manually:"
    echo "  - Kill remaining processes"
    echo "  - Remove remaining files"
    echo "  - Run: sudo systemctl daemon-reload"
fi
echo "=================================="
