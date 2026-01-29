# WordPress MCP Server

MCP (Model Context Protocol) сервер для управления WordPress постами через ChatGPT.

## Что это?

Позволяет ChatGPT создавать, обновлять, получать и удалять посты на вашем WordPress сайте.

## Быстрый старт

### 1. Скопируйте файлы на сервер

```bash
# На вашем Ubuntu сервере создайте директорию
mkdir -p ~/wordpress-mcp-project
cd ~/wordpress-mcp-project

# Скопируйте туда эти файлы:
# - mcp_sse_server.py
# - requirements.txt
# - install.sh
```

### 2. Настройте WordPress credentials

Откройте `mcp_sse_server.py` и измените:

```python
WORDPRESS_URL = "https://your-wordpress-site.com/"
WORDPRESS_USERNAME = "your-username"
WORDPRESS_PASSWORD = "your-password"
```

### 3. Запустите установку

```bash
chmod +x install.sh
sudo ./install.sh
```

Скрипт автоматически:
- Установит все зависимости
- Создаст виртуальное окружение Python
- Установит Python пакеты
- Создаст systemd сервис
- Запустит MCP сервер
- Установит Cloudflare Tunnel для HTTPS
- Выдаст HTTPS URL для подключения к ChatGPT

### 4. Подключите к ChatGPT

1. Откройте ChatGPT
2. Settings → Connectors → New Connector
3. Укажите:
   - **Name:** WordPress MCP
   - **URL:** `https://your-url.trycloudflare.com/sse` (из вывода install.sh)
   - **Authentication:** No authentication
4. Сохраните

### 5. Используйте!

Попросите ChatGPT:
```
Напиши статью про AI на 300 слов и опубликуй на моём WordPress сайте
```

## Архитектура

```
ChatGPT
  ↓ HTTPS/SSE
Cloudflare Tunnel
  ↓ HTTP
FastAPI MCP Server (port 8000)
  ↓ HTTPS
WordPress REST API
  ↓
WordPress Site
```

## Доступные инструменты

1. **create_post** - Создать новый пост
   - Параметры: title, content, excerpt (опционально), status (publish/draft/private)
   
2. **update_post** - Обновить существующий пост
   - Параметры: post_id, title (опционально), content (опционально), excerpt (опционально)
   
3. **get_posts** - Получить список постов
   - Параметры: per_page (1-100, по умолчанию 10), page (по умолчанию 1)
   
4. **delete_post** - Удалить пост
   - Параметры: post_id

## Управление

### Проверка статуса
```bash
sudo systemctl status wordpress-mcp-server
```

### Просмотр логов
```bash
sudo journalctl -u wordpress-mcp-server -f
```

### Перезапуск
```bash
sudo systemctl restart wordpress-mcp-server
```

### Получить HTTPS URL
```bash
cat ~/cloudflared.log | grep "https://"
```

### Перезапустить Cloudflare Tunnel
```bash
pkill cloudflared
nohup cloudflared tunnel --url http://localhost:8000 > ~/cloudflared.log 2>&1 &
sleep 5
cat ~/cloudflared.log | grep "https://"
```

## Troubleshooting

### Сервер не запускается

```bash
# Проверьте логи
sudo journalctl -u wordpress-mcp-server -n 50

# Проверьте порт
sudo netstat -tlnp | grep 8000
```

### ChatGPT не подключается

```bash
# Проверьте Cloudflare Tunnel
cat ~/cloudflared.log | grep "https://"

# Протестируйте URL
curl https://your-url.trycloudflare.com/health
```

### 401 ошибка при создании поста

Проверьте WordPress credentials в `mcp_sse_server.py`. Убедитесь, что:
- URL правильный и заканчивается на `/`
- Username и password корректные
- У пользователя есть права на создание постов
- WordPress REST API включен

### Ошибка "WordPress client not initialized"

Сервер не смог инициализировать WordPress клиент. Проверьте:
- Логи сервера: `sudo journalctl -u wordpress-mcp-server -n 50`
- Доступность WordPress сайта
- Правильность credentials

## Безопасность

⚠️ **Важно:**
- WordPress credentials хранятся в коде - используйте Application Password
- Нет аутентификации на MCP endpoint - добавьте API ключ для production
- Cloudflare бесплатный туннель может быть нестабилен

### Рекомендации для production:

1. **Используйте Application Password вместо основного пароля:**
   - В WordPress: Users → Profile → Application Passwords
   - Создайте новый Application Password для MCP
   
2. **Добавьте переменные окружения:**
   ```bash
   # Создайте .env файл
   echo "WORDPRESS_URL=https://your-site.com/" > .env
   echo "WORDPRESS_USERNAME=your-username" >> .env
   echo "WORDPRESS_PASSWORD=your-app-password" >> .env
   ```

3. **Добавьте API Key аутентификацию:**
   - Генерируйте уникальный API ключ
   - Проверяйте header `X-API-Key` на каждом запросе

4. **Используйте HTTPS:**
   - Настройте Nginx/Apache с SSL сертификатом
   - Используйте Let's Encrypt для бесплатных SSL сертификатов

## Требования

- Ubuntu 20.04+
- Python 3.10+
- WordPress с REST API (включен по умолчанию в WordPress 4.7+)
- Root или sudo доступ

## Расширение функционала

### Добавление новых инструментов

Чтобы добавить новые инструменты (например, работа с категориями):

1. Добавьте метод в класс `WordPressMCP`
2. Добавьте Tool в функцию `handle_list_tools()`
3. Добавьте обработку в функцию `handle_call_tool()`

Пример:
```python
async def get_categories(self):
    url = f"{self.api_base}/categories"
    response = await self.client.get(url)
    return response.json()
```

## Примеры использования

### Создание статьи через ChatGPT:
```
Пользователь: Напиши статью про Model Context Protocol на 500 слов и опубликуй

ChatGPT: Создаю статью...
[Использует create_post]
Статья опубликована на https://your-site.com/mcp-protocol/
```

### Получение последних постов:
```
Пользователь: Покажи последние 5 постов

ChatGPT: [Использует get_posts]
1. "MCP Protocol..." - https://your-site.com/mcp/
2. "AI Revolution" - https://your-site.com/ai-revolution/
...
```

### Создание черновика:
```
Пользователь: Создай черновик статьи про Python

ChatGPT: [Использует create_post со status="draft"]
Черновик создан! ID: 124
```

## Мониторинг

Для продакшена рекомендуется добавить:
- Prometheus метрики (количество запросов, ошибок, latency)
- Healthcheck endpoints
- Алерты при падении сервиса
- Логирование в централизованную систему (ELK, Loki)

## Лицензия

MIT - используйте свободно!

## Поддержка

При возникновении проблем:
1. Проверьте логи: `sudo journalctl -u wordpress-mcp-server -f`
2. Проверьте статус: `sudo systemctl status wordpress-mcp-server`
3. Протестируйте WordPress API напрямую:
   ```bash
   curl -u "username:password" https://your-site.com/wp-json/wp/v2/posts
   ```

## Авторы

Created with ❤️ using Model Context Protocol

## Ссылки

- [MCP Documentation](https://modelcontextprotocol.io/)
- [WordPress REST API](https://developer.wordpress.org/rest-api/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
