# 📖 WordPress MCP Server - Детальная инструкция по установке

**Пошаговое руководство с объяснениями**

---

## 📑 Содержание

1. [Подготовка системы](#1-подготовка-системы)
2. [Настройка WordPress](#2-настройка-wordpress)
3. [Установка проекта](#3-установка-проекта)
4. [Конфигурация](#4-конфигурация)
5. [Запуск сервера](#5-запуск-сервера)
6. [Настройка HTTPS туннеля](#6-настройка-https-туннеля)
7. [Подключение к ChatGPT](#7-подключение-к-chatgpt)
8. [Тестирование](#8-тестирование)
9. [Настройка автозапуска](#9-настройка-автозапуска)
10. [Мониторинг](#10-мониторинг)

---

## 1. Подготовка системы

### 1.1 Требования

**Операционная система:**
- Ubuntu 20.04 LTS или новее (рекомендуется 22.04)
- Debian 11+ также поддерживается
- Другие Linux с systemd (требует адаптации)

**Ресурсы:**
```
Минимальные:
- CPU: 1 core
- RAM: 512 MB
- Disk: 100 MB
- Network: 1 Mbps

Рекомендуемые:
- CPU: 2 cores
- RAM: 1 GB
- Disk: 500 MB
- Network: 10 Mbps
```

**Права доступа:**
- Root или sudo доступ (для установки systemd сервиса)
- Права на создание файлов в /opt
- Права на открытие порта 8000

### 1.2 Обновление системы

```bash
# Обновление списка пакетов
sudo apt update

# Обновление установленных пакетов
sudo apt upgrade -y

# Проверка версий
cat /etc/os-release
```

### 1.3 Установка базовых зависимостей

```bash
# Установка основных инструментов
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    net-tools \
    lsof

# Проверка установки
python3 --version  # Должно быть 3.10+
pip3 --version
git --version
```

**Объяснение зависимостей:**
- `python3` — основной интерпретатор
- `python3-pip` — менеджер пакетов Python
- `python3-venv` — виртуальные окружения
- `git` — для клонирования репозиториев
- `curl`, `wget` — загрузка файлов
- `net-tools`, `lsof` — диагностика сети

---

## 2. Настройка WordPress

### 2.1 Проверка REST API

WordPress REST API включен по умолчанию с версии 4.7+.

**Проверка доступности:**
```bash
curl https://your-wordpress-site.com/wp-json/wp/v2/posts
```

Если получили JSON с постами — API работает! ✅

**Если получили ошибку 404:**
1. Проверьте URL (должен быть с https://)
2. Убедитесь, что WordPress 4.7+
3. Проверьте, не отключен ли REST API плагином

### 2.2 Создание Application Password (рекомендуется)

**Что это:**
Application Password — безопасный способ авторизации для приложений без использования основного пароля.

**Как создать:**

1. Войдите в WordPress админку
2. Перейдите в: **Users → Your Profile**
3. Прокрутите вниз до: **Application Passwords**
4. В поле **New Application Password Name** введите: `MCP Server`
5. Нажмите **Add New Application Password**
6. **Скопируйте сгенерированный пароль** (показывается один раз!)

Пример: `abcd 1234 efgh 5678 ijkl 9012`

**Использование:**
```python
# В mcp_sse_server.py используйте этот пароль:
WORDPRESS_USERNAME = "admin"
WORDPRESS_PASSWORD = "abcd 1234 efgh 5678 ijkl 9012"  # Application Password
```

### 2.3 Проверка прав пользователя

Убедитесь, что пользователь имеет права:
- **Author** (может создавать и редактировать свои посты)
- **Editor** (может редактировать все посты)
- **Administrator** (полные права)

**Проверка через API:**
```bash
curl -u "username:password" \
  https://your-site.com/wp-json/wp/v2/users/me
```

Должно вернуть информацию о пользователе с `capabilities`.

---

## 3. Установка проекта

### 3.1 Выбор расположения

**Вариант A: Автоматическая установка в /opt (рекомендуется)**
```bash
# Скрипт install.sh установит в /opt/wordpress-mcp-server
sudo ./install.sh
```

**Вариант B: Ручная установка в домашней директории**
```bash
cd ~
mkdir wordpress-mcp
cd wordpress-mcp
```

**Вариант C: Установка в /var/www**
```bash
sudo mkdir -p /var/www/wordpress-mcp
sudo chown $USER:$USER /var/www/wordpress-mcp
cd /var/www/wordpress-mcp
```

### 3.2 Копирование файлов

**Способ 1: Через git (если есть репозиторий)**
```bash
git clone https://github.com/your-repo/wordpress-mcp-server.git
cd wordpress-mcp-server
```

**Способ 2: Через scp с локальной машины**
```bash
# На локальной машине:
scp mcp_sse_server.py requirements.txt install.sh \
    user@your-server:~/wordpress-mcp/
```

**Способ 3: Создание файлов вручную**
```bash
# Создайте каждый файл через nano/vim
nano mcp_sse_server.py  # Вставьте код
nano requirements.txt    # Вставьте зависимости
nano install.sh          # Вставьте скрипт установки
chmod +x install.sh
```

### 3.3 Проверка файлов

```bash
ls -lah

# Должны быть:
# -rw-r--r-- mcp_sse_server.py
# -rw-r--r-- requirements.txt
# -rwxr-xr-x install.sh
# и другие .sh и .md файлы
```

---

## 4. Конфигурация

### 4.1 Редактирование credentials

```bash
nano mcp_sse_server.py
```

**Найдите и измените (строки 27-29):**
```python
# БЫЛО:
WORDPRESS_URL = "https://your-wordpress-site.com/"
WORDPRESS_USERNAME = "your-username"
WORDPRESS_PASSWORD = "your-password"

# СТАЛО:
WORDPRESS_URL = "https://myblog.com/"
WORDPRESS_USERNAME = "admin"
WORDPRESS_PASSWORD = "abcd 1234 efgh 5678 ijkl 9012"  # Application Password
```

**Важно:**
- URL должен заканчиваться на `/`
- Используйте Application Password (см. раздел 2.2)
- Не используйте кавычки с пробелами в пароле

### 4.2 Использование переменных окружения (опционально, для production)

**Создайте файл .env:**
```bash
nano .env
```

**Содержимое:**
```env
WORDPRESS_URL=https://myblog.com/
WORDPRESS_USERNAME=admin
WORDPRESS_PASSWORD=abcd 1234 efgh 5678 ijkl 9012
MCP_SERVER_PORT=8000
```

**Измените mcp_sse_server.py:**
```python
import os
from dotenv import load_dotenv

load_dotenv()

WORDPRESS_URL = os.getenv("WORDPRESS_URL", "https://your-site.com/")
WORDPRESS_USERNAME = os.getenv("WORDPRESS_USERNAME", "admin")
WORDPRESS_PASSWORD = os.getenv("WORDPRESS_PASSWORD", "password")
```

### 4.3 Проверка конфигурации

**Тест подключения к WordPress:**
```bash
# Активируйте venv (если уже создан)
source venv/bin/activate

# Тест через curl
curl -u "username:password" https://myblog.com/wp-json/wp/v2/posts

# Должен вернуть JSON с постами
```

---

## 5. Запуск сервера

### 5.1 Создание виртуального окружения

```bash
# Создание venv
python3 -m venv venv

# Активация
source venv/bin/activate

# Проверка (должен появиться (venv) в начале строки)
which python  # Должно показать путь в venv
```

### 5.2 Установка зависимостей

```bash
# Обновление pip
pip install --upgrade pip

# Установка зависимостей
pip install -r requirements.txt

# Проверка установки
pip list
```

**Должны быть установлены:**
- mcp (1.0.0+)
- fastapi (0.104.0+)
- uvicorn (0.24.0+)
- httpx (0.25.0+)
- pydantic (2.5.0+)
- python-dotenv (1.0.0+)
- sse-starlette (2.0.0+)

### 5.3 Тестовый запуск

**Запуск вручную:**
```bash
python3 mcp_sse_server.py
```

**Ожидаемый вывод:**
```
==================================================
WordPress MCP Server
==================================================
WordPress URL: https://myblog.com/
Username: admin
==================================================
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**В другом терминале проверьте:**
```bash
curl http://localhost:8000/health
# {"status":"healthy","service":"wordpress-mcp-sse-server"}
```

**Остановка:** Нажмите `Ctrl+C`

### 5.4 Использование скрипта start_server.sh

```bash
chmod +x start_server.sh
./start_server.sh
```

Скрипт автоматически:
- Проверит зависимости
- Создаст venv (если нет)
- Активирует окружение
- Проверит конфигурацию
- Запустит сервер
- Выведет логи в консоль и server.log

---

## 6. Настройка HTTPS туннеля

### 6.1 Установка Cloudflare Tunnel

```bash
# Скачивание (выбирается автоматически по архитектуре)
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64

# Установка
chmod +x cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared

# Проверка
cloudflared --version
```

### 6.2 Запуск туннеля

**Вручную:**
```bash
cloudflared tunnel --url http://localhost:8000
```

**Через скрипт (рекомендуется):**
```bash
chmod +x restart_tunnel.sh
./restart_tunnel.sh
```

**Вывод:**
```
==================================
🚀 Starting new Cloudflare Tunnel...
==================================

✓ Tunnel started with PID: 23456
📝 Logs: /root/cloudflared.log

⏳ Waiting for tunnel URL...
..........

==================================
✅ TUNNEL READY!
==================================

🌐 Your HTTPS URL:
   https://abc-123-def.trycloudflare.com

📱 For ChatGPT use:
   https://abc-123-def.trycloudflare.com/sse
```

### 6.3 Проверка туннеля

```bash
# Тест health endpoint через tunnel
curl https://abc-123-def.trycloudflare.com/health

# Ожидается: {"status":"healthy"...}
```

### 6.4 Постоянный туннель (опционально)

**Для production используйте Named Tunnel:**

```bash
# Авторизация в Cloudflare
cloudflared tunnel login

# Создание именованного туннеля
cloudflared tunnel create wordpress-mcp

# Конфигурация
nano ~/.cloudflared/config.yml
```

**config.yml:**
```yaml
tunnel: wordpress-mcp
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: mcp.yourdomain.com
    service: http://localhost:8000
  - service: http_status:404
```

**Запуск:**
```bash
cloudflared tunnel run wordpress-mcp
```

---

## 7. Подключение к ChatGPT

### 7.1 Требования

- ChatGPT Plus, Team, или Enterprise
- GPT-4 модель
- Поддержка Actions/Connectors (зависит от версии)

### 7.2 Процесс подключения

**Шаг 1: Откройте настройки**
1. Войдите в ChatGPT
2. Нажмите на свой профиль (правый верхний угол)
3. Settings → Beta Features или Actions

**Шаг 2: Создайте коннектор**
1. Нажмите "New Connector" или "Create Action"
2. Заполните форму:

```
Name: WordPress MCP Server
Description: Manage WordPress posts through ChatGPT
URL: https://your-tunnel-url.trycloudflare.com/sse
Method: SSE (Server-Sent Events)
Authentication: None
```

**Шаг 3: Тестирование**
1. Нажмите "Test Connection"
2. Должно показать "Connected" с зеленым статусом
3. Нажмите "Save"

### 7.3 Альтернатива: OpenAI API

Если у вас нет доступа к ChatGPT Connectors:

```python
# Используйте OpenAI API напрямую
from openai import OpenAI

client = OpenAI()
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Create a post"}]
)
```

---

## 8. Тестирование

### 8.1 Локальное тестирование

**Тест 1: Health Check**
```bash
curl http://localhost:8000/health
```

**Тест 2: Server Info**
```bash
curl http://localhost:8000/ | jq
```

**Тест 3: MCP Initialize**
```bash
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | jq
```

**Тест 4: List Tools**
```bash
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | jq
```

**Тест 5: Create Post**
```bash
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "create_post",
      "arguments": {
        "title": "Test Post",
        "content": "<p>This is a test</p>",
        "status": "draft"
      }
    }
  }' | jq
```

### 8.2 Тестирование через туннель

Замените `localhost:8000` на ваш tunnel URL:

```bash
curl https://your-url.trycloudflare.com/health
```

### 8.3 Тестирование через ChatGPT

После подключения попросите ChatGPT:

```
Создай тестовый пост "Hello MCP" с текстом "This is a test post"
```

Проверьте в WordPress админке — пост должен появиться!

### 8.4 Использование check_status.sh

```bash
chmod +x check_status.sh
./check_status.sh
```

Скрипт проверит:
- ✅ Системные требования
- ✅ Файлы проекта
- ✅ MCP сервер (systemd и процесс)
- ✅ HTTP endpoints
- ✅ Cloudflare Tunnel
- ✅ Логи
- ✅ Общий статус

---

## 9. Настройка автозапуска

### 9.1 Создание systemd сервиса

**Автоматически (через install.sh):**
```bash
sudo ./install.sh  # Создаст сервис автоматически
```

**Вручную:**
```bash
sudo nano /etc/systemd/system/wordpress-mcp-server.service
```

**Содержимое:**
```ini
[Unit]
Description=WordPress MCP SSE Server for OpenAI
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/wordpress-mcp-server
Environment=PATH=/opt/wordpress-mcp-server/venv/bin
ExecStart=/opt/wordpress-mcp-server/venv/bin/python mcp_sse_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 9.2 Активация сервиса

```bash
# Перезагрузка конфигурации
sudo systemctl daemon-reload

# Включение автозапуска
sudo systemctl enable wordpress-mcp-server

# Запуск сервиса
sudo systemctl start wordpress-mcp-server

# Проверка статуса
sudo systemctl status wordpress-mcp-server
```

### 9.3 Управление сервисом

```bash
# Остановка
sudo systemctl stop wordpress-mcp-server

# Перезапуск
sudo systemctl restart wordpress-mcp-server

# Просмотр логов
sudo journalctl -u wordpress-mcp-server -f

# Последние 50 строк
sudo journalctl -u wordpress-mcp-server -n 50
```

### 9.4 Автозапуск Cloudflare Tunnel

**Создание systemd сервиса для туннеля:**
```bash
sudo nano /etc/systemd/system/cloudflared-tunnel.service
```

**Содержимое:**
```ini
[Unit]
Description=Cloudflare Tunnel for MCP Server
After=network.target wordpress-mcp-server.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --url http://localhost:8000 --logfile /var/log/cloudflared.log
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Активация:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-tunnel
sudo systemctl start cloudflared-tunnel
```

---

## 10. Мониторинг

### 10.1 Просмотр логов

**MCP Server:**
```bash
# Realtime
sudo journalctl -u wordpress-mcp-server -f

# Последние N строк
sudo journalctl -u wordpress-mcp-server -n 100

# С фильтрацией по дате
sudo journalctl -u wordpress-mcp-server --since "1 hour ago"
```

**Cloudflare Tunnel:**
```bash
tail -f /root/cloudflared.log
# или
tail -f /var/log/cloudflared.log  # если используется systemd сервис
```

### 10.2 Мониторинг процессов

```bash
# Проверка процессов
ps aux | grep mcp_sse_server
ps aux | grep cloudflared

# Проверка портов
sudo lsof -i :8000
sudo netstat -tulpn | grep 8000

# Использование ресурсов
top -p $(pgrep -f mcp_sse_server)
```

### 10.3 Автоматическая проверка (cron)

**Создание скрипта мониторинга:**
```bash
nano monitor.sh
```

**Содержимое:**
```bash
#!/bin/bash

# Проверка MCP сервера
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo "MCP Server is down! Restarting..."
    sudo systemctl restart wordpress-mcp-server
    
    # Отправка уведомления (опционально)
    # curl -X POST https://hooks.slack.com/... \
    #   -d '{"text":"MCP Server restarted"}'
fi

# Проверка туннеля
if ! pgrep -f cloudflared > /dev/null; then
    echo "Cloudflare Tunnel is down! Restarting..."
    ./restart_tunnel.sh
fi
```

**Добавление в cron:**
```bash
chmod +x monitor.sh
crontab -e

# Добавьте строку (проверка каждые 5 минут):
*/5 * * * * /opt/wordpress-mcp-server/monitor.sh >> /var/log/mcp-monitor.log 2>&1
```

### 10.4 Использование check_status.sh

```bash
# Однократная проверка
./check_status.sh

# Периодическая проверка (каждые 30 секунд)
watch -n 30 ./check_status.sh
```

---

## ✅ Проверочный чеклист

После выполнения всех шагов проверьте:

- [ ] Python 3.10+ установлен
- [ ] Все файлы проекта на месте
- [ ] WordPress credentials настроены
- [ ] Виртуальное окружение создано
- [ ] Зависимости установлены
- [ ] MCP сервер запускается
- [ ] Локальный health check работает (localhost:8000/health)
- [ ] Cloudflare Tunnel запущен
- [ ] HTTPS URL получен
- [ ] HTTPS health check работает
- [ ] ChatGPT подключен
- [ ] Тестовый пост создан успешно
- [ ] systemd сервис настроен
- [ ] Автозапуск работает (после перезагрузки)
- [ ] Логи доступны
- [ ] Мониторинг настроен

---

## 🎉 Готово!

Поздравляем! Вы успешно установили и настроили WordPress MCP Server.

**Следующие шаги:**
- [EXAMPLES.md](EXAMPLES.md) — Изучите примеры использования
- [FAQ.md](FAQ.md) — Ответы на частые вопросы
- [DEPLOYMENT.md](DEPLOYMENT.md) — Production развертывание

---

**Вопросы?** → [FAQ.md](FAQ.md)

**Проблемы?** → Используйте `./check_status.sh` для диагностики
