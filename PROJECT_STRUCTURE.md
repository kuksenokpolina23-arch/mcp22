# 🏗️ WordPress MCP Server - Архитектура проекта

**Полное описание структуры и компонентов**

---

## 📂 Структура проекта

```
wordpress-mcp-server/
├── mcp_sse_server.py          # Основной сервер (681 строка)
├── requirements.txt            # Python зависимости
│
├── install.sh                  # Автоматическая установка
├── start_server.sh             # Ручной запуск сервера
├── restart_tunnel.sh           # Перезапуск Cloudflare Tunnel
├── check_status.sh             # Проверка статуса
├── uninstall.sh                # Удаление проекта
│
├── GET_STARTED.md              # Главная точка входа
├── README.md                   # Основная документация
├── QUICK_START.md              # Быстрый старт (5 мин)
├── SETUP_GUIDE.md              # Детальная инструкция
├── EXAMPLES.md                 # 20+ примеров
├── FAQ.md                      # 40+ вопросов
├── DEPLOYMENT.md               # Production развертывание
├── USAGE_EXAMPLES.md           # Технические примеры
├── PROJECT_STRUCTURE.md        # Этот файл
├── CHANGELOG.md                # История изменений
├── PROJECT_SUMMARY.md          # Итоговая сводка
│
├── venv/                       # Виртуальное окружение Python
│   ├── bin/
│   ├── lib/
│   └── ...
│
├── .env                        # Переменные окружения (создается вручную)
├── .tunnel_url                 # Текущий URL туннеля (автоматически)
├── server.log                  # Логи сервера (если запущен вручную)
└── cloudflared.log             # Логи Cloudflare Tunnel
```

---

## 🎯 Компоненты системы

### 1. Основной сервер (mcp_sse_server.py)

**Размер:** 681 строка Python кода

**Структура:**

```python
# ============================================
# ИМПОРТЫ И КОНФИГУРАЦИЯ
# ============================================
import asyncio, json, logging, ...
WORDPRESS_URL = "..."
WORDPRESS_USERNAME = "..."
WORDPRESS_PASSWORD = "..."

# ============================================
# WORDPRESS API CLIENT
# ============================================
class WordPressMCP:
    def __init__(...)
    async def create_post(...)     # Создание поста
    async def update_post(...)     # Обновление поста
    async def get_posts(...)       # Получение постов
    async def delete_post(...)     # Удаление поста
    async def close(...)           # Закрытие клиента

# ============================================
# MCP SERVER
# ============================================
mcp_server = Server("wordpress-mcp-server")

@mcp_server.list_tools()          # Список инструментов
async def handle_list_tools()

@mcp_server.call_tool()           # Выполнение инструментов
async def handle_call_tool(...)

# ============================================
# FASTAPI APPLICATION
# ============================================
@asynccontextmanager
async def lifespan(app)           # Startup/Shutdown

app = FastAPI(...)
app.add_middleware(CORSMiddleware, ...)

@app.get("/")                     # Информация о сервере
@app.get("/health")               # Health check
@app.get("/sse")                  # SSE endpoint
@app.post("/mcp")                 # MCP JSON-RPC endpoint

# ============================================
# MAIN
# ============================================
if __name__ == "__main__":
    uvicorn.run(app, ...)
```

**Ключевые классы и функции:**

1. **WordPressMCP** — клиент для WordPress REST API
   - HTTP аутентификация (Basic Auth)
   - Async операции через httpx
   - Обработка ошибок

2. **MCP Server** — реализация Model Context Protocol
   - Регистрация tools
   - Обработка вызовов
   - Валидация входных данных

3. **FastAPI App** — HTTP сервер
   - SSE endpoints для ChatGPT
   - JSON-RPC endpoints для MCP
   - CORS middleware
   - Lifespan management

---

## 🔄 Поток данных

### Архитектура: ChatGPT → MCP Server → WordPress

```
┌─────────────┐
│   ChatGPT   │
│  (OpenAI)   │
└──────┬──────┘
       │ HTTPS/SSE
       ↓
┌──────────────────┐
│ Cloudflare       │
│ Tunnel           │
│ (HTTPS Proxy)    │
└──────┬───────────┘
       │ HTTP
       ↓
┌──────────────────┐
│ FastAPI          │ ← Port 8000
│ MCP Server       │
│ (mcp_sse_server) │
└──────┬───────────┘
       │ HTTPS
       ↓
┌──────────────────┐
│ WordPress        │
│ REST API         │
│ (/wp-json/...)   │
└──────────────────┘
```

### Детальный поток для create_post:

```
1. Пользователь → ChatGPT
   "Создай пост Hello World"

2. ChatGPT → MCP Server (SSE /sse)
   Установка SSE соединения

3. ChatGPT → MCP Server (POST /mcp)
   {
     "method": "tools/call",
     "params": {
       "name": "create_post",
       "arguments": {
         "title": "Hello World",
         "content": "<p>First post</p>"
       }
     }
   }

4. MCP Server → handle_call_tool()
   Валидация и роутинг

5. MCP Server → WordPressMCP.create_post()
   Формирование HTTP запроса

6. MCP Server → WordPress API
   POST /wp-json/wp/v2/posts
   Authorization: Basic base64(username:password)
   {
     "title": "Hello World",
     "content": "<p>First post</p>",
     "status": "publish"
   }

7. WordPress → MCP Server
   {
     "id": 123,
     "link": "https://myblog.com/hello-world/",
     ...
   }

8. MCP Server → ChatGPT
   {
     "result": {
       "content": [{
         "type": "text",
         "text": "{\"success\":true,\"post_id\":123,...}"
       }]
     }
   }

9. ChatGPT → Пользователь
   "✅ Пост создан! URL: https://myblog.com/hello-world/"
```

---

## 🛠️ Технологический стек

### Backend:
- **Python 3.10+** — основной язык
- **FastAPI** — веб-фреймворк
- **Uvicorn** — ASGI сервер
- **httpx** — async HTTP клиент
- **Pydantic** — валидация данных
- **MCP Python SDK** — Model Context Protocol

### Инфраструктура:
- **systemd** — управление сервисом
- **Cloudflare Tunnel** — HTTPS proxy
- **Ubuntu 20.04+** — операционная система

### WordPress:
- **WordPress 4.7+** — CMS
- **REST API** — интеграция (wp-json/wp/v2)
- **Basic Auth** — аутентификация

### ChatGPT Integration:
- **SSE (Server-Sent Events)** — real-time связь
- **JSON-RPC 2.0** — протокол вызовов
- **MCP Protocol** — стандарт OpenAI

---

## 📊 Endpoints

### 1. GET /
**Назначение:** Информация о сервере

**Ответ:**
```json
{
  "name": "WordPress MCP SSE Server",
  "version": "1.0.0",
  "protocol": "MCP over SSE",
  "endpoints": {
    "info": "/",
    "health": "/health",
    "sse": "/sse",
    "mcp": "/mcp"
  },
  "tools": [...]
}
```

---

### 2. GET /health
**Назначение:** Health check для мониторинга

**Ответ:**
```json
{
  "status": "healthy",
  "service": "wordpress-mcp-sse-server"
}
```

**Использование:**
- Проверка доступности: `curl http://localhost:8000/health`
- Kubernetes liveness probe
- Load balancer health checks
- Мониторинг (Prometheus, Datadog)

---

### 3. GET /sse
**Назначение:** SSE endpoint для ChatGPT

**Формат:**
```
event: endpoint
data: {"url": "http://server:8000/mcp"}

event: heartbeat
data: {"status": "alive"}

event: heartbeat
data: {"status": "alive"}
...
```

**Особенности:**
- Heartbeat каждые 15 секунд
- Keep-alive соединение
- Headers: `Cache-Control: no-cache`, `X-Accel-Buffering: no`

---

### 4. POST /mcp
**Назначение:** MCP JSON-RPC endpoint

**Поддерживаемые методы:**

#### 4.1 initialize
**Запрос:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize"
}
```

**Ответ:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {"tools": {}},
    "serverInfo": {
      "name": "wordpress-mcp-server",
      "version": "1.0.0"
    }
  }
}
```

#### 4.2 tools/list
**Запрос:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}
```

**Ответ:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "create_post",
        "description": "Create a new WordPress post",
        "inputSchema": {...}
      },
      ...
    ]
  }
}
```

#### 4.3 tools/call
**Запрос:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "create_post",
    "arguments": {
      "title": "Hello",
      "content": "<p>World</p>"
    }
  }
}
```

**Ответ:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [{
      "type": "text",
      "text": "{\"success\":true,\"post_id\":123,...}"
    }]
  }
}
```

---

## 🔧 MCP Tools

### 1. create_post

**Назначение:** Создание нового поста WordPress

**Параметры:**
```json
{
  "title": "string (обязательно)",
  "content": "string (обязательно, HTML)",
  "excerpt": "string (опционально)",
  "status": "enum: publish|draft|private (опционально, по умолчанию: publish)"
}
```

**Возврат:**
```json
{
  "success": true,
  "post_id": 123,
  "url": "https://myblog.com/post-url/",
  "message": "Post created successfully",
  "status": "publish"
}
```

---

### 2. update_post

**Назначение:** Обновление существующего поста

**Параметры:**
```json
{
  "post_id": "integer (обязательно)",
  "title": "string (опционально)",
  "content": "string (опционально, HTML)",
  "excerpt": "string (опционально)"
}
```

**Возврат:**
```json
{
  "success": true,
  "post_id": 123,
  "url": "https://myblog.com/post-url/",
  "message": "Post updated successfully"
}
```

---

### 3. get_posts

**Назначение:** Получение списка постов

**Параметры:**
```json
{
  "per_page": "integer (1-100, по умолчанию: 10)",
  "page": "integer (по умолчанию: 1)"
}
```

**Возврат:**
```json
{
  "success": true,
  "posts": [
    {
      "id": 123,
      "title": "Post Title",
      "url": "https://myblog.com/post/",
      "status": "publish",
      "date": "2025-01-28T10:00:00"
    },
    ...
  ],
  "count": 10,
  "message": "Retrieved 10 posts"
}
```

---

### 4. delete_post

**Назначение:** Удаление поста (permanent)

**Параметры:**
```json
{
  "post_id": "integer (обязательно)"
}
```

**Возврат:**
```json
{
  "success": true,
  "post_id": 123,
  "message": "Post deleted successfully"
}
```

---

## 🔐 Безопасность

### Уровни безопасности:

#### Development (текущая реализация):
- ✅ Basic Auth для WordPress
- ✅ HTTPS через Cloudflare Tunnel
- ✅ CORS настроен (`allow_origins=["*"]`)
- ❌ Нет аутентификации на MCP endpoint
- ❌ Нет rate limiting
- ❌ Credentials в коде

#### Production (рекомендуется):
- ✅ Environment variables для credentials
- ✅ API Key аутентификация на /mcp
- ✅ Rate limiting (slowapi)
- ✅ CORS ограничен конкретными origins
- ✅ HTTPS с валидным сертификатом
- ✅ Firewall rules
- ✅ Мониторинг и логирование
- ✅ Security headers (CSP, X-Frame-Options, etc.)

---

## 📈 Масштабирование

### Горизонтальное:
```
Load Balancer
    ↓
┌────────────────┬────────────────┬────────────────┐
│ MCP Server 1   │ MCP Server 2   │ MCP Server 3   │
└────────────────┴────────────────┴────────────────┘
                   ↓
            WordPress Cluster
```

### Вертикальное:
- Увеличение RAM/CPU
- Оптимизация httpx client (connection pooling)
- Кеширование get_posts результатов
- Async workers для Uvicorn

---

## 🔌 Расширяемость

### Добавление нового tool:

**Шаг 1:** Добавьте метод в WordPressMCP:
```python
async def get_categories(self):
    url = f"{self.api_base}/categories"
    response = await self.client.get(url)
    return response.json()
```

**Шаг 2:** Добавьте Tool в list_tools():
```python
Tool(
    name="get_categories",
    description="Get WordPress categories",
    inputSchema={"type": "object", "properties": {}}
)
```

**Шаг 3:** Добавьте обработку в call_tool():
```python
elif name == "get_categories":
    result = await wp_client.get_categories()
```

### Интеграция с другими CMS:

Замените WordPressMCP на:
- DrupalMCP
- GhostMCP
- StrapiMCP
- etc.

MCP протокол остается неизменным!

---

## 📊 Метрики и мониторинг

### Рекомендуемые метрики:

1. **Производительность:**
   - Request latency (p50, p95, p99)
   - Requests per second
   - Error rate

2. **Доступность:**
   - Uptime
   - Health check status
   - WordPress API availability

3. **Бизнес метрики:**
   - Posts created per day
   - Most used tools
   - Active users (ChatGPT instances)

### Реализация (Prometheus):

```python
from prometheus_client import Counter, Histogram

requests_total = Counter('mcp_requests_total', 'Total requests')
request_duration = Histogram('mcp_request_duration', 'Request duration')

@app.post("/mcp")
async def mcp_endpoint(request: Request):
    requests_total.inc()
    with request_duration.time():
        # ... код
```

---

## 🎓 Дополнительные ресурсы

- **[DEPLOYMENT.md](DEPLOYMENT.md)** — Production развертывание
- **[EXAMPLES.md](EXAMPLES.md)** — Примеры расширения
- **[FAQ.md](FAQ.md)** — Частые вопросы по архитектуре

---

**Версия:** 1.0.0  
**Последнее обновление:** 2025-01-28
