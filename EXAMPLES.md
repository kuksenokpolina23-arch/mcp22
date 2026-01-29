# 💡 WordPress MCP Server - Примеры использования

**20+ практических примеров для разных сценариев**

---

## 📑 Содержание

- [Базовые операции](#базовые-операции)
- [Работа с черновиками](#работа-с-черновиками)
- [Массовое создание контента](#массовое-создание-контента)
- [HTML форматирование](#html-форматирование)
- [Обновление постов](#обновление-постов)
- [Управление через Python](#управление-через-python)
- [Использование curl](#использование-через-curl)
- [Автоматизация и планирование](#автоматизация-и-планирование)
- [Интеграция с другими сервисами](#интеграция-с-другими-сервисами)
- [Продвинутые сценарии](#продвинутые-сценарии)

---

## Базовые операции

### Пример 1: Создание простого поста

**Команда для ChatGPT:**
```
Создай пост "Hello World" с текстом "Мой первый пост через MCP"
```

**Что происходит:**
ChatGPT использует `create_post` tool:
```json
{
  "title": "Hello World",
  "content": "<p>Мой первый пост через MCP</p>",
  "status": "publish"
}
```

**Результат:**
```
✅ Пост создан!
Post ID: 123
URL: https://myblog.com/hello-world/
Status: publish
```

---

### Пример 2: Получение последних постов

**Команда для ChatGPT:**
```
Покажи мне последние 5 постов с моего сайта
```

**Что происходит:**
ChatGPT использует `get_posts` tool:
```json
{
  "per_page": 5,
  "page": 1
}
```

**Результат:**
```
Вот ваши последние 5 постов:

1. Hello World (ID: 123)
   URL: https://myblog.com/hello-world/
   Status: publish
   Date: 2025-01-28

2. AI in 2025 (ID: 122)
   URL: https://myblog.com/ai-2025/
   Status: publish
   Date: 2025-01-27

...
```

---

### Пример 3: Удаление поста

**Команда для ChatGPT:**
```
Удали пост с ID 123
```

**Что происходит:**
ChatGPT использует `delete_post` tool:
```json
{
  "post_id": 123
}
```

**Результат:**
```
✅ Пост удалён!
Post ID: 123
```

---

## Работа с черновиками

### Пример 4: Создание черновика

**Команда для ChatGPT:**
```
Создай черновик статьи "Python для начинающих" — не публикуй
```

**Что происходит:**
```json
{
  "title": "Python для начинающих",
  "content": "<p>Полное руководство...</p>",
  "status": "draft"  ← Важно!
}
```

**Результат:**
```
✅ Черновик создан!
Post ID: 124
Status: draft
Вы можете отредактировать и опубликовать позже в WordPress
```

---

### Пример 5: Создание приватного поста

**Команда для ChatGPT:**
```
Создай приватный пост "Внутренние заметки" для команды
```

**Что происходит:**
```json
{
  "title": "Внутренние заметки",
  "content": "<p>Информация для команды...</p>",
  "status": "private"
}
```

**Результат:**
Пост виден только залогиненным пользователям WordPress.

---

### Пример 6: Публикация черновика

**Шаг 1:** Создайте черновик (Пример 4)

**Шаг 2:** Обновите его со статусом publish:
```
Опубликуй пост с ID 124
```

ChatGPT обновит пост:
```json
{
  "post_id": 124,
  "status": "publish"  ← Обратите внимание
}
```

---

## Массовое создание контента

### Пример 7: Серия статей

**Команда для ChatGPT:**
```
Создай серию из 3 статей:
1. "JavaScript: Основы" — про переменные и типы данных
2. "JavaScript: Функции" — про объявление и стрелочные функции
3. "JavaScript: Объекты" — про объекты и прототипы
```

**Что происходит:**
ChatGPT создаст 3 отдельных поста последовательно.

**Результат:**
```
✅ Создано 3 статьи:

1. JavaScript: Основы
   ID: 125
   URL: https://myblog.com/javascript-basics/

2. JavaScript: Функции
   ID: 126
   URL: https://myblog.com/javascript-functions/

3. JavaScript: Объекты
   ID: 127
   URL: https://myblog.com/javascript-objects/
```

---

### Пример 8: Ежедневные посты на неделю

**Команда для ChatGPT:**
```
Создай 7 мотивационных постов на каждый день недели.
Заголовок: "Мотивация понедельника", "Мотивация вторника" и т.д.
Все как черновики — я опубликую их по дням
```

**Результат:**
7 черновиков готовы к публикации по расписанию.

---

## HTML форматирование

### Пример 9: Пост с заголовками и списками

**Команда для ChatGPT:**
```
Создай пост "10 советов по продуктивности" со списком:
- Каждый совет должен быть подзаголовком H3
- Краткое объяснение под каждым
- Нумерованный список в конце с ключевыми выводами
```

**Что происходит:**
ChatGPT сгенерирует HTML:
```html
<h2>10 советов по продуктивности</h2>

<h3>1. Начинайте с самого важного</h3>
<p>Выполняйте сложные задачи утром...</p>

<h3>2. Используйте технику Pomodoro</h3>
<p>25 минут работы, 5 минут отдыха...</p>

...

<h3>Ключевые выводы:</h3>
<ol>
<li>Приоритизируйте задачи</li>
<li>Делайте перерывы</li>
<li>Используйте инструменты автоматизации</li>
</ol>
```

---

### Пример 10: Пост с изображениями (через URL)

**Команда для ChatGPT:**
```
Создай пост "Красивые пейзажи" с 3 изображениями:
https://example.com/image1.jpg
https://example.com/image2.jpg
https://example.com/image3.jpg
```

**Что происходит:**
```html
<h2>Красивые пейзажи</h2>

<img src="https://example.com/image1.jpg" alt="Пейзаж 1">
<p>Описание первого изображения...</p>

<img src="https://example.com/image2.jpg" alt="Пейзаж 2">
<p>Описание второго изображения...</p>

<img src="https://example.com/image3.jpg" alt="Пейзаж 3">
<p>Описание третьего изображения...</p>
```

---

### Пример 11: Пост с цитатами и выделениями

**Команда для ChatGPT:**
```
Создай пост про стоицизм с цитатами Марка Аврелия.
Используй blockquote для цитат и strong для ключевых фраз
```

**Результат:**
```html
<h2>Философия стоицизма</h2>

<p>Стоицизм учит нас <strong>контролировать</strong> то, что в нашей власти...</p>

<blockquote>
"Ты имеешь власть над своим разумом, а не над внешними событиями. 
Осознай это — и ты обретёшь силу."
— Марк Аврелий
</blockquote>

<p>Эта <strong>мудрость</strong> актуальна и сегодня...</p>
```

---

## Обновление постов

### Пример 12: Обновление заголовка

**Команда для ChatGPT:**
```
Обнови пост 125, измени заголовок на "JavaScript: Полное руководство по основам"
```

**Что происходит:**
```json
{
  "post_id": 125,
  "title": "JavaScript: Полное руководство по основам"
}
```

---

### Пример 13: Добавление текста в конец

**Команда для ChatGPT:**
```
Обнови пост 125, добавь в конец:
"P.S. Обновлено в январе 2025 с новыми примерами"
```

**Что происходит:**
ChatGPT:
1. Получит текущий контент поста
2. Добавит новый текст в конец
3. Обновит пост

---

### Пример 14: Исправление ошибки

**Команда для ChatGPT:**
```
В посте 126 есть ошибка в примере кода — 
вместо "function hello()" должно быть "const hello = () =>"
Исправь это
```

ChatGPT найдет и исправит ошибку в контенте.

---

## Управление через Python

### Пример 15: Создание поста через Python

```python
import httpx
import json
import asyncio

async def create_wordpress_post():
    url = "https://your-tunnel-url.trycloudflare.com/mcp"
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": "Test from Python",
                "content": "<p>Created programmatically</p>",
                "status": "draft"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        result = response.json()
        
        # Парсинг результата
        content = json.loads(result["result"]["content"][0]["text"])
        
        print(f"Post ID: {content['post_id']}")
        print(f"URL: {content['url']}")

# Запуск
asyncio.run(create_wordpress_post())
```

---

### Пример 16: Массовый импорт из CSV

```python
import csv
import asyncio
import httpx
import json

async def import_posts_from_csv(csv_file, mcp_url):
    """Импорт постов из CSV файла"""
    
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        async with httpx.AsyncClient() as client:
            for row in reader:
                payload = {
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "tools/call",
                    "params": {
                        "name": "create_post",
                        "arguments": {
                            "title": row['title'],
                            "content": row['content'],
                            "excerpt": row.get('excerpt', ''),
                            "status": row.get('status', 'draft')
                        }
                    }
                }
                
                response = await client.post(mcp_url, json=payload)
                result = response.json()
                content = json.loads(result["result"]["content"][0]["text"])
                
                print(f"✓ Created: {content['post_id']} - {row['title']}")
                
                await asyncio.sleep(1)  # Задержка между постами

# Использование
asyncio.run(import_posts_from_csv(
    'posts.csv',
    'https://your-url.trycloudflare.com/mcp'
))
```

**CSV файл (posts.csv):**
```csv
title,content,excerpt,status
"Post 1","<p>Content 1</p>","Excerpt 1",publish
"Post 2","<p>Content 2</p>","Excerpt 2",draft
"Post 3","<p>Content 3</p>","Excerpt 3",publish
```

---

### Пример 17: Получение и экспорт всех постов

```python
import asyncio
import httpx
import json
import csv

async def export_all_posts(mcp_url, output_file):
    """Экспорт всех постов в CSV"""
    
    all_posts = []
    page = 1
    
    async with httpx.AsyncClient() as client:
        while True:
            payload = {
                "jsonrpc": "2.0",
                "id": page,
                "method": "tools/call",
                "params": {
                    "name": "get_posts",
                    "arguments": {
                        "per_page": 100,
                        "page": page
                    }
                }
            }
            
            response = await client.post(mcp_url, json=payload)
            result = response.json()
            content = json.loads(result["result"]["content"][0]["text"])
            
            if not content['posts']:
                break
            
            all_posts.extend(content['posts'])
            page += 1
            print(f"Fetched page {page-1}: {len(content['posts'])} posts")
    
    # Экспорт в CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['id', 'title', 'url', 'status', 'date'])
        writer.writeheader()
        writer.writerows(all_posts)
    
    print(f"\n✓ Exported {len(all_posts)} posts to {output_file}")

asyncio.run(export_all_posts(
    'https://your-url.trycloudflare.com/mcp',
    'wordpress_posts_export.csv'
))
```

---

## Использование через curl

### Пример 18: Создание поста через curl

```bash
curl -X POST https://your-url.trycloudflare.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "create_post",
      "arguments": {
        "title": "Test from curl",
        "content": "<p>Simple test</p>",
        "status": "draft"
      }
    }
  }' | jq '.result.content[0].text | fromjson'
```

---

### Пример 19: Bash скрипт для массового создания

```bash
#!/bin/bash

# create_posts.sh - Создание постов из файла

MCP_URL="https://your-url.trycloudflare.com/mcp"

# Читаем каждую строку из posts.txt
while IFS='|' read -r title content; do
    echo "Creating: $title"
    
    curl -X POST "$MCP_URL" \
      -H "Content-Type: application/json" \
      -s \
      -d "{
        \"jsonrpc\": \"2.0\",
        \"id\": 1,
        \"method\": \"tools/call\",
        \"params\": {
          \"name\": \"create_post\",
          \"arguments\": {
            \"title\": \"$title\",
            \"content\": \"<p>$content</p>\",
            \"status\": \"draft\"
          }
        }
      }" | jq -r '.result.content[0].text | fromjson | "✓ Post ID: \(.post_id)"'
    
    sleep 2
done < posts.txt

echo "Done!"
```

**Файл posts.txt:**
```
Hello World|My first post
Second Post|Another great post
Third Post|Even more content
```

**Запуск:**
```bash
chmod +x create_posts.sh
./create_posts.sh
```

---

## Автоматизация и планирование

### Пример 20: Ежедневный автопостинг (cron)

**Создайте скрипт daily_post.py:**
```python
import asyncio
import httpx
import json
from datetime import datetime

async def create_daily_post():
    mcp_url = "https://your-url.trycloudflare.com/mcp"
    
    today = datetime.now().strftime("%Y-%m-%d")
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": f"Daily Update - {today}",
                "content": "<p>Автоматический ежедневный пост</p>",
                "status": "publish"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(mcp_url, json=payload)
        print(f"Daily post created for {today}")

asyncio.run(create_daily_post())
```

**Добавьте в crontab:**
```bash
crontab -e

# Добавьте (каждый день в 9:00):
0 9 * * * /usr/bin/python3 /path/to/daily_post.py >> /var/log/daily_post.log 2>&1
```

---

### Пример 21: Планировщик с APScheduler

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler
import asyncio
import httpx
import json
from datetime import datetime

async def create_scheduled_post(title, content, mcp_url):
    """Создание запланированного поста"""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": title,
                "content": content,
                "status": "publish"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(mcp_url, json=payload)
        print(f"Scheduled post created: {title}")

# Настройка планировщика
scheduler = AsyncIOScheduler()

MCP_URL = "https://your-url.trycloudflare.com/mcp"

# Пост каждый день в 9:00
scheduler.add_job(
    create_scheduled_post,
    'cron',
    hour=9,
    args=['Morning Post', '<p>Good morning!</p>', MCP_URL]
)

# Пост каждый понедельник в 10:00
scheduler.add_job(
    create_scheduled_post,
    'cron',
    day_of_week='mon',
    hour=10,
    args=['Weekly Summary', '<p>Week summary...</p>', MCP_URL]
)

scheduler.start()

# Держать работающим
asyncio.get_event_loop().run_forever()
```

---

## Интеграция с другими сервисами

### Пример 22: Импорт из RSS

```python
import feedparser
import asyncio
import httpx
import json

async def import_from_rss(rss_url, mcp_url):
    """Импорт постов из RSS канала"""
    
    feed = feedparser.parse(rss_url)
    
    async with httpx.AsyncClient() as client:
        for entry in feed.entries[:5]:  # Первые 5 постов
            payload = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "create_post",
                    "arguments": {
                        "title": entry.title,
                        "content": entry.summary,
                        "excerpt": entry.get('description', '')[:150],
                        "status": "draft"
                    }
                }
            }
            
            response = await client.post(mcp_url, json=payload)
            result = response.json()
            content = json.loads(result["result"]["content"][0]["text"])
            
            print(f"✓ Imported: {entry.title}")
            await asyncio.sleep(1)

# Использование
asyncio.run(import_from_rss(
    'https://example.com/feed',
    'https://your-url.trycloudflare.com/mcp'
))
```

---

## Продвинутые сценарии

### Пример 23: AI-генерация контента + автопостинг

```python
from openai import OpenAI
import asyncio
import httpx
import json

openai_client = OpenAI(api_key="your-api-key")

async def generate_and_post(topic, mcp_url):
    """Генерация статьи через OpenAI + публикация"""
    
    # 1. Генерация контента через OpenAI
    response = openai_client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a blog writer"},
            {"role": "user", "content": f"Write a 500-word article about: {topic}"}
        ]
    )
    
    content = response.choices[0].message.content
    
    # 2. Публикация на WordPress
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": f"AI Article: {topic}",
                "content": f"<p>{content}</p>",
                "status": "publish"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(mcp_url, json=payload)
        result = response.json()
        content_result = json.loads(result["result"]["content"][0]["text"])
        
        print(f"✓ AI article published: {content_result['url']}")

# Использование
asyncio.run(generate_and_post(
    "Machine Learning in 2025",
    "https://your-url.trycloudflare.com/mcp"
))
```

---

### Пример 24: Мониторинг и авто-обновление

```python
import asyncio
import httpx
import json

async def auto_update_outdated_posts(mcp_url):
    """Автоматическое добавление пометки к старым постам"""
    
    async with httpx.AsyncClient() as client:
        # 1. Получить все посты
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "get_posts",
                "arguments": {"per_page": 100, "page": 1}
            }
        }
        
        response = await client.post(mcp_url, json=payload)
        result = response.json()
        content = json.loads(result["result"]["content"][0]["text"])
        
        # 2. Обновить старые посты
        for post in content['posts']:
            post_date = datetime.fromisoformat(post['date'])
            days_old = (datetime.now() - post_date).days
            
            if days_old > 365:  # Старше года
                # Добавить пометку
                update_payload = {
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "tools/call",
                    "params": {
                        "name": "update_post",
                        "arguments": {
                            "post_id": post['id'],
                            "excerpt": f"Обновлено: {datetime.now().strftime('%Y-%m-%d')}"
                        }
                    }
                }
                
                await client.post(mcp_url, json=update_payload)
                print(f"✓ Updated old post: {post['title']}")

asyncio.run(auto_update_outdated_posts(
    "https://your-url.trycloudflare.com/mcp"
))
```

---

## 🎓 Дополнительные ресурсы

- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** — Технические примеры кода
- **[FAQ.md](FAQ.md)** — Частые вопросы
- **[README.md](README.md)** — Полная документация

---

**Есть свой интересный пример?** Добавьте его в документацию!
