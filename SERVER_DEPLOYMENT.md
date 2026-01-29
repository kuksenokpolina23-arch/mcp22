# 🚀 Развертывание MCP Server на 77.73.232.84

## ⚡ БЫСТРЫЙ СТАРТ

Ты уже подключен к серверу. Теперь просто скопируй и вставь эту команду:

```bash
curl -sSL https://raw.githubusercontent.com/kuksenokpolina23-arch/mcp22/main/deploy_to_server.sh | bash
```

**ИЛИ** используй команды ниже:

---

## 📋 Метод 1: Автоматический (скопируй и вставь целиком)

Вставь весь этот блок в терминал на сервере:

```bash
cd /root && \
git clone https://github.com/kuksenokpolina23-arch/mcp22.git && \
cd mcp22 && \
apt update && apt install -y python3-pip python3-venv && \
pip3 install --upgrade pip && \
pip3 install -r requirements.txt && \
chmod +x *.sh && \
pkill -f mcp_sse_server.py 2>/dev/null; true && \
nohup python3 mcp_sse_server.py > mcp_server.log 2>&1 & \
sleep 3 && \
echo "=== Server Status ===" && \
ps aux | grep mcp_sse_server.py | grep -v grep && \
echo "" && \
echo "=== Listening Ports ===" && \
netstat -tlnp | grep python && \
echo "" && \
echo "=== Recent Logs ===" && \
tail -15 mcp_server.log && \
echo "" && \
echo "✓ Deployment complete!"
```

---

## 📋 Метод 2: Пошаговый (если нужен контроль)

### Шаг 1: Клонирование проекта

```bash
cd /root
git clone https://github.com/kuksenokpolina23-arch/mcp22.git
cd mcp22
ls -la
```

### Шаг 2: Установка зависимостей

```bash
# Обновить систему
apt update

# Установить pip
apt install -y python3-pip python3-venv

# Проверить Python
python3 --version
```

### Шаг 3: Установка Python пакетов

```bash
# Обновить pip
pip3 install --upgrade pip

# Установить зависимости проекта
pip3 install -r requirements.txt

# Проверить установку
pip3 list | grep -iE 'fastapi|uvicorn|sse|starlette'
```

### Шаг 4: Подготовка скриптов

```bash
# Сделать скрипты исполняемыми
chmod +x *.sh

# Проверить основной файл
ls -la mcp_sse_server.py
```

### Шаг 5: Запуск сервера

```bash
# Остановить старый процесс (если есть)
pkill -f mcp_sse_server.py

# Запустить сервер в фоне
nohup python3 mcp_sse_server.py > mcp_server.log 2>&1 &

# Подождать загрузки
sleep 3
```

### Шаг 6: Проверка статуса

```bash
# Проверить процесс
ps aux | grep mcp_sse_server.py | grep -v grep

# Проверить порты
netstat -tlnp | grep python

# Посмотреть логи
tail -20 mcp_server.log
```

---

## 📋 Метод 3: Используя готовые скрипты

После клонирования проекта на сервере:

```bash
cd /root/mcp22

# Запуск
./start_server.sh

# Проверка статуса
./check_status.sh

# Остановка
pkill -f mcp_sse_server.py
```

---

## 🔧 Управление сервером

### Просмотр логов в реальном времени:
```bash
tail -f /root/mcp22/mcp_server.log
```

### Остановка сервера:
```bash
pkill -f mcp_sse_server.py
```

### Перезапуск сервера:
```bash
pkill -f mcp_sse_server.py && sleep 2 && cd /root/mcp22 && nohup python3 mcp_sse_server.py > mcp_server.log 2>&1 &
```

### Проверка статуса:
```bash
ps aux | grep mcp_sse_server.py | grep -v grep
netstat -tlnp | grep python
```

### Обновление кода с GitHub:
```bash
cd /root/mcp22
git pull origin main
pkill -f mcp_sse_server.py
sleep 2
nohup python3 mcp_sse_server.py > mcp_server.log 2>&1 &
```

---

## 🎯 Что будет установлено:

Из `requirements.txt`:
- **fastapi** - Web framework
- **uvicorn** - ASGI server
- **sse-starlette** - Server-Sent Events
- **pydantic** - Data validation
- **python-multipart** - Form data handling
- И другие зависимости

---

## 📊 Проверка работы

После запуска сервер должен слушать на порту (обычно 8000):

```bash
# Локальная проверка
curl http://localhost:8000/health

# Проверка извне (если firewall настроен)
curl http://77.73.232.84:8000/health
```

---

## 🔥 Настройка автозапуска (опционально)

Создать systemd service:

```bash
cat > /etc/systemd/system/mcp-server.service << 'EOF'
[Unit]
Description=MCP SSE Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/mcp22
ExecStart=/usr/bin/python3 /root/mcp22/mcp_sse_server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Активировать службу
systemctl daemon-reload
systemctl enable mcp-server
systemctl start mcp-server
systemctl status mcp-server
```

---

## 🆘 Решение проблем

### Если git не установлен:
```bash
apt install -y git
```

### Если Python не найден:
```bash
apt install -y python3 python3-pip
```

### Если порт занят:
```bash
# Найти процесс
lsof -i :8000

# Убить процесс
kill -9 <PID>
```

### Если ошибки в логах:
```bash
# Полный лог
cat /root/mcp22/mcp_server.log

# Последние ошибки
grep -i error /root/mcp22/mcp_server.log
```

---

## ✅ Проверка успешного развертывания

Ты увидишь что-то вроде:

```
✓ Project cloned
✓ Python 3.x.x installed
✓ Dependencies installed
✓ Server running (PID: xxxxx)
✓ Listening on: 0.0.0.0:8000
```

---

**Просто скопируй блок команд из Метода 1 и вставь в терминал - всё установится автоматически!** 🚀
