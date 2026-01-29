# ❓ WordPress MCP Server - Частые вопросы (FAQ)

**30+ ответов на типичные вопросы**

---

## 📑 Содержание

- [Общие вопросы](#общие-вопросы)
- [Установка и настройка](#установка-и-настройка)
- [WordPress интеграция](#wordpress-интеграция)
- [Cloudflare Tunnel](#cloudflare-tunnel)
- [ChatGPT подключение](#chatgpt-подключение)
- [Ошибки и troubleshooting](#ошибки-и-troubleshooting)
- [Безопасность](#безопасность)
- [Production использование](#production-использование)
- [Расширение функционала](#расширение-функционала)

---

## Общие вопросы

### 1. Что такое WordPress MCP Server?

**Ответ:**  
Это сервер, который реализует Model Context Protocol (MCP) для управления WordPress постами через ChatGPT. Вы можете просить ChatGPT создавать, редактировать и удалять посты на вашем WordPress сайте естественным языком.

**Пример:**
```
Вы: "Напиши статью про AI на 500 слов и опубликуй"
ChatGPT: *создает и публикует статью на вашем сайте*
```

---

### 2. Нужен ли мне ChatGPT Plus?

**Ответ:**  
Да, для использования Connectors/Actions требуется ChatGPT Plus, Team, или Enterprise подписка с доступом к GPT-4.

Альтернатива: Вы можете использовать OpenAI API напрямую без ChatGPT Plus.

---

### 3. Какие версии WordPress поддерживаются?

**Ответ:**  
WordPress 4.7+ (любая версия с REST API, который включен по умолчанию).

Проверка:
```bash
curl https://your-site.com/wp-json/wp/v2/posts
```

Если получили JSON — всё работает!

---

### 4. Нужен ли мне выделенный сервер?

**Ответ:**  
Нет, подойдет:
- VPS (Digital Ocean, Linode, Vultr и т.д.)
- Shared hosting с SSH доступом
- Домашний сервер с Ubuntu
- Cloud платформы (AWS, GCP, Azure)

Минимум: 512 MB RAM, 1 CPU core.

---

### 5. Можно ли запустить на Windows?

**Ответ:**  
Проект ориентирован на Linux (Ubuntu), но можно адаптировать для Windows:

1. Установите Python 3.10+
2. Запустите вручную: `python mcp_sse_server.py`
3. Используйте Cloudflare Tunnel для Windows
4. systemd скрипты не нужны

**Или используйте WSL2** (Windows Subsystem for Linux) — там всё будет работать как на Ubuntu.

---

## Установка и настройка

### 6. Где получить файлы проекта?

**Ответ:**  
Все файлы созданы и находятся в директории проекта:
- `mcp_sse_server.py` — основной код
- `requirements.txt` — зависимости
- `install.sh` — автоустановка
- Все `.md` файлы — документация
- Все `.sh` файлы — скрипты управления

---

### 7. install.sh не запускается: Permission denied

**Ответ:**  
Добавьте права на выполнение:
```bash
chmod +x install.sh
sudo ./install.sh
```

---

### 8. Ошибка: "Python3 not found"

**Ответ:**  
Установите Python:
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
python3 --version  # Проверка
```

---

### 9. pip install не работает: "externally-managed-environment"

**Ответ:**  
Это защита в новых версиях Debian/Ubuntu. Используйте виртуальное окружение (venv), как и предполагалось:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

### 10. Как изменить порт с 8000 на другой?

**Ответ:**  
Откройте `mcp_sse_server.py` и измените в самом конце:

```python
# БЫЛО:
uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")

# СТАЛО:
uvicorn.run(app, host="0.0.0.0", port=9000, log_level="info")
```

Также обновите в:
- systemd сервисе (`/etc/systemd/system/wordpress-mcp-server.service`)
- Cloudflare Tunnel команде: `--url http://localhost:9000`
- Firewall: `sudo ufw allow 9000/tcp`

---

## WordPress интеграция

### 11. 401 Unauthorized при создании поста

**Ответ:**  
Неверные credentials. Проверьте:

1. **URL правильный:**
   ```python
   WORDPRESS_URL = "https://myblog.com/"  # С https:// и / на конце!
   ```

2. **Username существует:**
   Войдите в WordPress админку с этим username.

3. **Password правильный:**
   Используйте Application Password (см. вопрос 12).

4. **REST API включен:**
   ```bash
   curl https://myblog.com/wp-json/wp/v2/posts
   ```

---

### 12. Что такое Application Password и где его взять?

**Ответ:**  
Application Password — безопасный способ авторизации для приложений.

**Как создать:**
1. WordPress админка → Users → Your Profile
2. Прокрутите вниз до "Application Passwords"
3. Введите имя: `MCP Server`
4. Нажмите "Add New Application Password"
5. **Скопируйте пароль** (показывается один раз!)

Пример: `abcd 1234 efgh 5678`

**Использование:**
```python
WORDPRESS_PASSWORD = "abcd 1234 efgh 5678"  # Со всеми пробелами!
```

---

### 13. Application Passwords не отображаются в WordPress

**Ответ:**  
Application Passwords требуют HTTPS. Решения:

1. **Лучший вариант:** Настройте SSL на WordPress (Let's Encrypt бесплатно)
2. **Временный вариант:** Используйте основной пароль (небезопасно!)
3. **Для development:** Добавьте в `wp-config.php`:
   ```php
   define('APPLICATION_PASSWORD_AVAILABLE', true);
   ```

---

### 14. Можно ли управлять несколькими WordPress сайтами?

**Ответ:**  
Из коробки — нет (один сервер = один WordPress).

**Решения:**

**Вариант 1:** Запустите несколько серверов на разных портах:
```bash
# Сайт 1 на порту 8000
python mcp_sse_server.py

# Сайт 2 на порту 8001 (измените порт в коде)
python mcp_sse_server_site2.py
```

**Вариант 2:** Модифицируйте код для поддержки multiple sites:
```python
# Добавьте параметр site_id в каждый метод
async def create_post(site_id: str, title: str, ...):
    url = SITES[site_id]["url"]
    # ...
```

---

### 15. Поддерживаются ли другие типы контента (страницы, custom post types)?

**Ответ:**  
Сейчас только posts. Но легко добавить:

**Для страниц:**
```python
async def create_page(self, title: str, content: str):
    url = f"{self.api_base}/pages"  # /pages вместо /posts
    # ... остальное аналогично create_post
```

**Для custom post types:**
```python
async def create_product(self, title: str, ...):
    url = f"{self.api_base}/products"  # Ваш CPT slug
    # ...
```

Затем добавьте Tool в `@mcp_server.list_tools()`.

---

## Cloudflare Tunnel

### 16. Что такое Cloudflare Tunnel и зачем он нужен?

**Ответ:**  
Cloudflare Tunnel создает HTTPS соединение от вашего локального сервера к Cloudflare без необходимости:
- Открывать порты в firewall
- Покупать SSL сертификат
- Иметь белый IP адрес

ChatGPT требует HTTPS, поэтому туннель необходим.

---

### 17. Cloudflare Tunnel URL постоянно меняется

**Ответ:**  
Бесплатные quick tunnels (`trycloudflare.com`) получают случайный URL при каждом запуске.

**Решения:**

**1. Запускайте туннель постоянно:**
```bash
# Не убивайте процесс cloudflared
# Используйте systemd для автозапуска
```

**2. Используйте Named Tunnel (рекомендуется для production):**
```bash
cloudflared tunnel login
cloudflared tunnel create mcp-tunnel
# Настройте config.yml с вашим доменом
cloudflared tunnel run mcp-tunnel
```

Теперь URL будет постоянным: `mcp.yourdomain.com`

---

### 18. Cloudflare Tunnel не работает: "Unable to reach the origin service"

**Ответ:**  
MCP сервер не запущен или недоступен.

**Проверка:**
```bash
# 1. Проверьте MCP сервер
curl http://localhost:8000/health

# 2. Если не работает — запустите:
./start_server.sh
# или
sudo systemctl start wordpress-mcp-server

# 3. После запуска перезапустите туннель:
./restart_tunnel.sh
```

---

### 19. Можно ли использовать Ngrok вместо Cloudflare Tunnel?

**Ответ:**  
Да! Ngrok работает аналогично:

```bash
# Установка
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-*.tgz
sudo mv ngrok /usr/local/bin/

# Запуск
ngrok http 8000

# Скопируйте https://... URL из вывода
```

**Или другие альтернативы:**
- **localtunnel:** `npx localtunnel --port 8000`
- **Serveo:** `ssh -R 80:localhost:8000 serveo.net`
- **Telebit:** Более безопасная альтернатива

---

### 20. Как получить постоянный HTTPS URL?

**Ответ:**  
Используйте один из способов:

**1. Named Cloudflare Tunnel** (бесплатно, рекомендуется)
```bash
cloudflared tunnel login
cloudflared tunnel create mcp
# Настройте DNS: mcp.yourdomain.com → tunnel
cloudflared tunnel run mcp
```

**2. Nginx + Let's Encrypt** (если есть белый IP)
```bash
sudo apt install nginx certbot python3-certbot-nginx
sudo certbot --nginx -d mcp.yourdomain.com
# Proxy pass в nginx: localhost:8000
```

**3. Ngrok платная подписка** ($8/месяц)
```bash
ngrok http 8000 --domain=mcp.yourdomain.com
```

---

## ChatGPT подключение

### 21. Где найти Connectors/Actions в ChatGPT?

**Ответ:**  
Расположение зависит от версии ChatGPT:

**ChatGPT Plus (2024+):**
1. Профиль → Settings
2. Beta Features или Actions
3. Connectors или MCP

**ChatGPT Enterprise:**
1. Admin console
2. Integrations → Actions

**Если не находите:** Эта функция может быть еще в бета-тестировании для вашего аккаунта.

---

### 22. "Connection failed" при подключении к ChatGPT

**Ответ:**  
Проверьте пошагово:

1. **Проверьте URL:**
   ```
   Должно быть: https://your-url.trycloudflare.com/sse
   НЕ: http://... (без s)
   НЕ: без /sse на конце
   ```

2. **Проверьте доступность:**
   ```bash
   curl https://your-url.trycloudflare.com/health
   ```
   Должно вернуть: `{"status":"healthy"}`

3. **Проверьте SSE endpoint:**
   ```bash
   curl -N https://your-url.trycloudflare.com/sse
   ```
   Должны появиться SSE events

4. **Проверьте логи:**
   ```bash
   sudo journalctl -u wordpress-mcp-server -f
   ```

---

### 23. ChatGPT подключен, но не может создать пост

**Ответ:**  
ChatGPT подключился к MCP серверу, но сервер не может подключиться к WordPress.

**Проверка:**
1. **Проверьте WordPress credentials** в `mcp_sse_server.py`
2. **Тест подключения:**
   ```bash
   curl -u "username:password" https://myblog.com/wp-json/wp/v2/posts
   ```
3. **Посмотрите логи MCP сервера:**
   ```bash
   sudo journalctl -u wordpress-mcp-server -n 50
   ```
4. **Типичные ошибки:**
   - 401: Неверный username/password
   - 403: Нет прав на создание постов
   - 404: Неверный URL WordPress
   - Timeout: WordPress недоступен

---

### 24. У меня нет ChatGPT Plus, как использовать?

**Ответ:**  
Используйте OpenAI API напрямую:

```python
from openai import OpenAI

client = OpenAI(api_key="your-api-key")

response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Create a post about AI"}
    ]
)

print(response.choices[0].message.content)
```

Или используйте MCP endpoint напрямую через curl/Python:
```bash
curl -X POST https://your-url/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{...}}'
```

---

## Ошибки и troubleshooting

### 25. "Address already in use" при запуске

**Ответ:**  
Порт 8000 уже занят другим процессом.

**Решение 1: Остановите старый процесс**
```bash
# Найдите процесс
sudo lsof -i :8000

# Убейте процесс
sudo kill -9 <PID>

# Или автоматически
sudo lsof -ti:8000 | xargs kill -9
```

**Решение 2: Измените порт**
См. вопрос 10.

---

### 26. ModuleNotFoundError: No module named 'mcp'

**Ответ:**  
Зависимости не установлены или venv не активирован.

**Решение:**
```bash
# Активируйте venv
source venv/bin/activate

# Установите зависимости
pip install -r requirements.txt

# Проверка
pip list | grep mcp
```

---

### 27. "SSL: CERTIFICATE_VERIFY_FAILED" при подключении к WordPress

**Ответ:**  
Проблема с SSL сертификатом WordPress сайта.

**Временное решение (НЕБЕЗОПАСНО для production):**
В `mcp_sse_server.py` измените:
```python
self.client = httpx.AsyncClient(
    auth=(username, password),
    timeout=30.0,
    verify=False  # ← Отключение проверки SSL
)
```

**Правильное решение:**
Настройте валидный SSL сертификат на WordPress (Let's Encrypt).

---

### 28. MCP сервер запускается, но сразу падает

**Ответ:**  
Проверьте логи для диагностики:

```bash
# systemd логи
sudo journalctl -u wordpress-mcp-server -n 50

# Или запустите вручную
source venv/bin/activate
python3 mcp_sse_server.py
```

**Типичные причины:**
- SyntaxError в коде → проверьте Python версию (нужен 3.10+)
- Import errors → переустановите зависимости
- Permission denied → запустите с sudo или измените права

---

### 29. Cloudflare Tunnel запускается, но URL не появляется

**Ответ:**  
Подождите 15-30 секунд. Если не помогло:

```bash
# Проверьте логи
cat ~/cloudflared.log

# Или
tail -f ~/cloudflared.log
```

**Если в логах ошибки:**
- "unable to reach origin" → MCP сервер не запущен
- "authentication error" → проблема с Cloudflare аккаунтом
- "too many tunnels" → закройте старые туннели: `pkill cloudflared`

---

### 30. После перезагрузки сервера ничего не работает

**Ответ:**  
Systemd сервис не настроен или не включен.

**Решение:**
```bash
# Проверка статуса
sudo systemctl status wordpress-mcp-server

# Если disabled:
sudo systemctl enable wordpress-mcp-server
sudo systemctl start wordpress-mcp-server

# Проверка автозапуска
sudo systemctl is-enabled wordpress-mcp-server
```

**Для Cloudflare Tunnel:**
Создайте systemd сервис (см. SETUP_GUIDE.md раздел 9.4).

---

## Безопасность

### 31. Безопасно ли хранить credentials в коде?

**Ответ:**  
**Нет, для production это небезопасно.**

**Лучшие практики:**

1. **Используйте переменные окружения:**
   ```bash
   # Создайте .env файл
   echo "WORDPRESS_PASSWORD=secret" > .env
   chmod 600 .env  # Только владелец может читать
   ```
   ```python
   # В коде
   from dotenv import load_dotenv
   load_dotenv()
   WORDPRESS_PASSWORD = os.getenv("WORDPRESS_PASSWORD")
   ```

2. **Используйте secrets management:**
   - AWS Secrets Manager
   - HashiCorp Vault
   - Docker secrets
   - Kubernetes secrets

3. **Используйте Application Password** вместо основного пароля

---

### 32. Как добавить API Key аутентификацию?

**Ответ:**  
Добавьте проверку header в `/mcp` endpoint:

```python
from fastapi import Header, HTTPException

@app.post("/mcp")
async def mcp_endpoint(
    request: Request,
    x_api_key: str = Header(None)
):
    # Проверка API ключа
    if x_api_key != os.getenv("MCP_API_KEY"):
        raise HTTPException(status_code=401, detail="Invalid API Key")
    
    # ... остальной код
```

Затем в ChatGPT при подключении укажите:
```
Authentication: API Key
Header: X-API-Key
Value: your-secret-key
```

---

### 33. Нужен ли firewall?

**Ответ:**  
Зависит от настройки:

**Если используете Cloudflare Tunnel:** Firewall не обязателен (туннель работает через исходящие соединения).

**Если НЕ используете туннель:**
```bash
# Включите firewall
sudo ufw enable

# Откройте только нужный порт
sudo ufw allow 8000/tcp

# Проверка
sudo ufw status
```

**Production рекомендация:**
- Используйте firewall всегда
- Открывайте только необходимые порты
- Настройте fail2ban против bruteforce
- Используйте IP whitelisting если возможно

---

## Production использование

### 34. Какие изменения нужны для production?

**Ответ:**  
См. [DEPLOYMENT.md](DEPLOYMENT.md) для полного списка. Основное:

1. ✅ Переменные окружения вместо hardcoded credentials
2. ✅ API Key аутентификация на MCP endpoint
3. ✅ Rate limiting (slowapi, nginx)
4. ✅ HTTPS с валидным сертификатом
5. ✅ Мониторинг (Prometheus, Grafana)
6. ✅ Логирование в централизованную систему
7. ✅ Backup и disaster recovery план
8. ✅ CI/CD pipeline
9. ✅ Health checks и auto-restart
10. ✅ Security headers (CORS, CSP, etc.)

---

### 35. Как добавить rate limiting?

**Ответ:**  
Используйте slowapi:

```bash
pip install slowapi
```

```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.post("/mcp")
@limiter.limit("10/minute")  # 10 запросов в минуту
async def mcp_endpoint(request: Request):
    # ...
```

---

### 36. Как настроить мониторинг?

**Ответ:**  
Добавьте Prometheus метрики:

```python
from prometheus_client import Counter, Histogram, generate_latest

# Метрики
requests_total = Counter('mcp_requests_total', 'Total requests')
errors_total = Counter('mcp_errors_total', 'Total errors')
request_duration = Histogram('mcp_request_duration_seconds', 'Request duration')

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")

# В каждом endpoint:
requests_total.inc()
with request_duration.time():
    # ... ваш код
```

Затем настройте Prometheus scraping и визуализацию в Grafana.

---

## Расширение функционала

### 37. Как добавить поддержку категорий и тегов?

**Ответ:**  
Добавьте новые методы в WordPressMCP:

```python
async def get_categories(self):
    url = f"{self.api_base}/categories"
    response = await self.client.get(url)
    return response.json()

async def create_post_with_category(self, title, content, category_id):
    url = f"{self.api_base}/posts"
    payload = {
        "title": title,
        "content": content,
        "categories": [category_id]  # Массив ID категорий
    }
    response = await self.client.post(url, json=payload)
    return response.json()
```

Затем добавьте Tools в `@mcp_server.list_tools()`.

---

### 38. Можно ли добавить загрузку изображений?

**Ответ:**  
Да! WordPress REST API поддерживает медиа:

```python
async def upload_image(self, image_path: str):
    url = f"{self.api_base}/media"
    
    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = await self.client.post(
            url,
            files=files,
            headers={'Content-Disposition': f'attachment; filename="{os.path.basename(image_path)}"'}
        )
    
    return response.json()

async def create_post_with_image(self, title, content, image_path):
    # 1. Загрузить изображение
    media = await self.upload_image(image_path)
    media_id = media['id']
    
    # 2. Создать пост с featured image
    url = f"{self.api_base}/posts"
    payload = {
        "title": title,
        "content": content,
        "featured_media": media_id
    }
    response = await self.client.post(url, json=payload)
    return response.json()
```

---

### 39. Как интегрировать с другими CMS (не WordPress)?

**Ответ:**  
Замените WordPressMCP класс на свою реализацию:

**Для Drupal:**
```python
class DrupalMCP:
    async def create_post(self, title, content):
        url = f"{self.base_url}/jsonapi/node/article"
        # ... Drupal JSON:API
```

**Для Ghost:**
```python
class GhostMCP:
    async def create_post(self, title, content):
        url = f"{self.base_url}/ghost/api/v3/admin/posts"
        # ... Ghost Admin API
```

**Для Strapi:**
```python
class StrapiMCP:
    async def create_post(self, title, content):
        url = f"{self.base_url}/api/posts"
        # ... Strapi REST API
```

MCP протокол универсален — меняйте только backend!

---

### 40. Где найти больше примеров?

**Ответ:**  
Смотрите документацию:
- [EXAMPLES.md](EXAMPLES.md) — 20+ структурированных примеров
- [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md) — Технические примеры кода
- [README.md](README.md) — Общая документация

---

## 🆘 Не нашли ответ?

1. **Проверьте документацию:**
   - [README.md](README.md)
   - [SETUP_GUIDE.md](SETUP_GUIDE.md)
   - [DEPLOYMENT.md](DEPLOYMENT.md)

2. **Запустите диагностику:**
   ```bash
   ./check_status.sh
   ```

3. **Посмотрите логи:**
   ```bash
   sudo journalctl -u wordpress-mcp-server -f
   ```

4. **Проверьте GitHub Issues** (если есть репозиторий)

---

**Последнее обновление:** 2025-01-28  
**Версия:** 1.0.0
