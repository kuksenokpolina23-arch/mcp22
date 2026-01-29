# Примеры использования WordPress MCP Server

## В ChatGPT

### Пример 1: Создание статьи

```
Пользователь: Напиши статью про Model Context Protocol на 500 слов и опубликуй на моём сайте

ChatGPT: Создаю статью про MCP...

[Использует инструмент create_post с параметрами:
- title: "Model Context Protocol: Революция в AI интеграции"
- content: "<p>Полный текст статьи...</p>"
- status: "publish"]

Статья "Model Context Protocol: Революция в AI интеграции" опубликована!
URL: https://your-site.com/model-context-protocol/
Post ID: 145
```

### Пример 2: Получение последних постов

```
Пользователь: Покажи мне последние 5 постов с моего сайта

ChatGPT: [Использует инструмент get_posts с per_page=5]

Вот ваши последние 5 постов:

1. "Model Context Protocol: Революция в AI интеграции"
   URL: https://your-site.com/model-context-protocol/
   Status: publish
   Date: 2025-01-28

2. "AI Revolution in Web Development"
   URL: https://your-site.com/ai-revolution/
   Status: publish
   Date: 2025-01-27

3. "Building Better APIs"
   URL: https://your-site.com/building-better-apis/
   Status: publish
   Date: 2025-01-26

4. "Python Best Practices 2025"
   URL: https://your-site.com/python-best-practices/
   Status: draft
   Date: 2025-01-25

5. "FastAPI vs Django"
   URL: https://your-site.com/fastapi-vs-django/
   Status: publish
   Date: 2025-01-24
```

### Пример 3: Обновление поста

```
Пользователь: Обнови пост с ID 123, добавь в конец "P.S. Обновлено в январе 2025"

ChatGPT: [Сначала получает текущий контент поста, затем использует update_post]

Пост обновлён успешно!
Post ID: 123
URL: https://your-site.com/my-post/
```

### Пример 4: Создание черновика

```
Пользователь: Создай черновик статьи про Python для начинающих, не публикуй

ChatGPT: [Использует create_post со status="draft"]

Черновик создан!
Post ID: 124
Status: draft
Название: "Python для начинающих: Полное руководство"

Вы можете опубликовать его позже или отредактировать в WordPress панели.
```

### Пример 5: Удаление поста

```
Пользователь: Удали пост с ID 100

ChatGPT: [Использует delete_post с post_id=100]

Пост удалён успешно!
Post ID: 100
```

### Пример 6: Массовое создание постов

```
Пользователь: Создай 3 статьи про JavaScript: основы, функции и объекты

ChatGPT: Создаю 3 статьи про JavaScript...

[Использует create_post 3 раза]

Все статьи созданы:

1. "JavaScript: Основы программирования"
   URL: https://your-site.com/javascript-basics/
   Post ID: 150

2. "JavaScript: Работа с функциями"
   URL: https://your-site.com/javascript-functions/
   Post ID: 151

3. "JavaScript: Объекты и прототипы"
   URL: https://your-site.com/javascript-objects/
   Post ID: 152
```

### Пример 7: Публикация с excerpt

```
Пользователь: Напиши статью про FastAPI с коротким описанием для превью

ChatGPT: [Использует create_post с параметрами:
- title: "FastAPI: Современный веб-фреймворк для Python"
- content: "<p>Полный текст статьи...</p>"
- excerpt: "Узнайте, как FastAPI позволяет создавать быстрые и современные API"
- status: "publish"]

Статья опубликована с превью!
URL: https://your-site.com/fastapi-guide/
```

## Через Python (прямые HTTP запросы)

### Создание поста

```python
import httpx
import json

async def create_post():
    url = "https://your-url.trycloudflare.com/mcp"
    
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": "Test Post from Python",
                "content": "<p>This is a test post created via Python</p>",
                "status": "draft"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        print(json.dumps(response.json(), indent=2))

# Запуск
import asyncio
asyncio.run(create_post())
```

### Получение постов

```python
import httpx
import json

async def get_posts():
    url = "https://your-url.trycloudflare.com/mcp"
    
    payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/call",
        "params": {
            "name": "get_posts",
            "arguments": {
                "per_page": 5,
                "page": 1
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        result = response.json()
        
        # Парсинг результата
        content = json.loads(result["result"]["content"][0]["text"])
        
        print(f"Найдено постов: {content['count']}")
        for post in content['posts']:
            print(f"- {post['title']} (ID: {post['id']})")

import asyncio
asyncio.run(get_posts())
```

### Обновление поста

```python
import httpx
import json

async def update_post():
    url = "https://your-url.trycloudflare.com/mcp"
    
    payload = {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "update_post",
            "arguments": {
                "post_id": 123,
                "title": "Updated Title",
                "content": "<p>Updated content</p>"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)
        print(json.dumps(response.json(), indent=2))

import asyncio
asyncio.run(update_post())
```

## Через curl (Command Line)

### Список инструментов

```bash
curl -X POST https://your-url.trycloudflare.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }' | jq
```

### Создать пост

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
        "title": "Test Post from curl",
        "content": "<p>This is a test</p>",
        "status": "draft"
      }
    }
  }' | jq
```

### Получить посты

```bash
curl -X POST https://your-url.trycloudflare.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "get_posts",
      "arguments": {
        "per_page": 5
      }
    }
  }' | jq
```

### Удалить пост

```bash
curl -X POST https://your-url.trycloudflare.com/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "delete_post",
      "arguments": {
        "post_id": 123
      }
    }
  }' | jq
```

## Через OpenAI Python SDK (в разработке)

```python
from openai import OpenAI

client = OpenAI()

# Использование MCP инструментов через OpenAI API
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "user", "content": "Create a blog post about AI"}
    ],
    tools=[
        {
            "type": "function",
            "function": {
                "name": "create_post",
                "description": "Create a WordPress post",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "content": {"type": "string"}
                    }
                }
            }
        }
    ]
)

print(response)
```

## Интеграция с другими сервисами

### Автоматическая публикация RSS

```python
import feedparser
import asyncio
import httpx

async def publish_from_rss(rss_url: str):
    """Читает RSS и публикует посты на WordPress"""
    feed = feedparser.parse(rss_url)
    
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
                    "status": "draft"
                }
            }
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://your-url.trycloudflare.com/mcp",
                json=payload
            )
            print(f"Published: {entry.title}")

asyncio.run(publish_from_rss("https://example.com/feed"))
```

### Планировщик постов (с APScheduler)

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler
import httpx
import asyncio

async def scheduled_post():
    """Создаёт пост по расписанию"""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "create_post",
            "arguments": {
                "title": f"Daily Update {datetime.now().date()}",
                "content": "<p>Daily automated post</p>",
                "status": "publish"
            }
        }
    }
    
    async with httpx.AsyncClient() as client:
        await client.post("https://your-url.trycloudflare.com/mcp", json=payload)

# Создать планировщик
scheduler = AsyncIOScheduler()
scheduler.add_job(scheduled_post, 'cron', hour=9)  # Каждый день в 9:00
scheduler.start()

# Держать работающим
asyncio.get_event_loop().run_forever()
```

## Тестирование

### Простой тест всех операций

```python
import httpx
import json
import asyncio

async def test_all_operations():
    """Тест всех операций MCP сервера"""
    base_url = "https://your-url.trycloudflare.com/mcp"
    
    async with httpx.AsyncClient() as client:
        # 1. Создать пост
        print("1. Creating post...")
        create_response = await client.post(base_url, json={
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {
                "name": "create_post",
                "arguments": {
                    "title": "Test Post",
                    "content": "<p>Test content</p>",
                    "status": "draft"
                }
            }
        })
        create_result = json.loads(
            create_response.json()["result"]["content"][0]["text"]
        )
        post_id = create_result["post_id"]
        print(f"✓ Post created: ID={post_id}")
        
        # 2. Получить посты
        print("\n2. Getting posts...")
        get_response = await client.post(base_url, json={
            "jsonrpc": "2.0",
            "id": 2,
            "method": "tools/call",
            "params": {
                "name": "get_posts",
                "arguments": {"per_page": 5}
            }
        })
        get_result = json.loads(
            get_response.json()["result"]["content"][0]["text"]
        )
        print(f"✓ Retrieved {get_result['count']} posts")
        
        # 3. Обновить пост
        print("\n3. Updating post...")
        update_response = await client.post(base_url, json={
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": {
                "name": "update_post",
                "arguments": {
                    "post_id": post_id,
                    "title": "Updated Test Post"
                }
            }
        })
        print("✓ Post updated")
        
        # 4. Удалить пост
        print("\n4. Deleting post...")
        delete_response = await client.post(base_url, json={
            "jsonrpc": "2.0",
            "id": 4,
            "method": "tools/call",
            "params": {
                "name": "delete_post",
                "arguments": {"post_id": post_id}
            }
        })
        print("✓ Post deleted")
        
        print("\n✅ All tests passed!")

asyncio.run(test_all_operations())
```

## Заключение

WordPress MCP Server предоставляет мощный и простой способ интеграции WordPress с ChatGPT и другими AI-системами через Model Context Protocol. Вы можете использовать его для:

- Автоматической генерации контента
- Массовой публикации постов
- Управления контентом через естественный язык
- Интеграции с другими сервисами
- Автоматизации рутинных задач

Для получения дополнительной информации см. `README.md`.
