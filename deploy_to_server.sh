#!/bin/bash
# MCP22 Server Deployment Script
# Run this on the remote server

set -e  # Exit on error

echo "======================================"
echo "MCP22 Server Deployment"
echo "======================================"
echo ""

# Step 1: Clone project
echo "Step 1: Cloning project from GitHub..."
cd /root
if [ -d "mcp22" ]; then
    echo "Directory mcp22 already exists. Updating..."
    cd mcp22
    git pull origin main
else
    git clone https://github.com/kuksenokpolina23-arch/mcp22.git
    cd mcp22
fi
echo "✓ Project cloned/updated"
echo ""

# Step 2: Check Python
echo "Step 2: Checking Python..."
python3 --version
echo ""

# Step 3: Update system and install dependencies
echo "Step 3: Installing system dependencies..."
apt update
apt install -y python3-pip python3-venv
echo "✓ System dependencies installed"
echo ""

# Step 4: Install Python packages
echo "Step 4: Installing Python packages..."
pip3 install --upgrade pip
pip3 install -r requirements.txt
echo "✓ Python packages installed"
echo ""

# Step 5: Verify installation
echo "Step 5: Verifying installation..."
pip3 list | grep -iE 'fastapi|uvicorn|sse|starlette|pydantic'
echo ""

# Step 6: Make scripts executable
echo "Step 6: Setting up scripts..."
chmod +x *.sh
ls -la *.sh
echo "✓ Scripts are executable"
echo ""

# Step 7: Check if server is already running
echo "Step 7: Checking for running instances..."
if pgrep -f "mcp_sse_server.py" > /dev/null; then
    echo "⚠ MCP server is already running. Stopping it..."
    pkill -f "mcp_sse_server.py"
    sleep 2
fi
echo "✓ No conflicts"
echo ""

# Step 8: Start the server
echo "Step 8: Starting MCP SSE Server..."
nohup python3 mcp_sse_server.py > mcp_server.log 2>&1 &
SERVER_PID=$!
echo "Server started with PID: $SERVER_PID"
sleep 3
echo ""

# Step 9: Verify server is running
echo "Step 9: Verifying server status..."
if ps -p $SERVER_PID > /dev/null; then
    echo "✓ Server is running (PID: $SERVER_PID)"
else
    echo "✗ Server failed to start. Check logs:"
    tail -20 mcp_server.log
    exit 1
fi
echo ""

# Step 10: Check listening ports
echo "Step 10: Checking listening ports..."
netstat -tlnp | grep python || ss -tlnp | grep python
echo ""

# Step 11: Display server info
echo "======================================"
echo "Deployment Summary"
echo "======================================"
echo "✓ Project location: /root/mcp22"
echo "✓ Server PID: $SERVER_PID"
echo "✓ Log file: /root/mcp22/mcp_server.log"
echo ""
echo "Recent log entries:"
tail -15 mcp_server.log
echo ""
echo "======================================"
echo "Server is running!"
echo "======================================"
echo ""
echo "Useful commands:"
echo "  - View logs: tail -f /root/mcp22/mcp_server.log"
echo "  - Stop server: pkill -f mcp_sse_server.py"
echo "  - Restart: cd /root/mcp22 && ./start_server.sh"
echo "  - Check status: ps aux | grep mcp_sse_server"
echo ""
