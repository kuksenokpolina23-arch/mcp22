#!/usr/bin/env python3
"""
WordPress MCP SSE Server for OpenAI and ChatGPT
Allows ChatGPT to create, update, get, and delete WordPress posts via MCP protocol
"""

import asyncio
import json
import logging
import os
from contextlib import asynccontextmanager
from typing import Any, Dict, List, Optional
from pathlib import Path

import httpx
import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sse_starlette.sse import EventSourceResponse
from dotenv import load_dotenv

from mcp.server import Server
from mcp.types import Tool, TextContent

# ============================================
# LOAD ENVIRONMENT VARIABLES
# ============================================

# Load .env file from the same directory as this script
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

# ============================================
# CONFIGURATION - LOADED FROM .env FILE
# ============================================

WORDPRESS_URL = os.getenv("WORDPRESS_URL", "https://your-wordpress-site.com")
WORDPRESS_USERNAME = os.getenv("WORDPRESS_USERNAME", "your-username")
WORDPRESS_PASSWORD = os.getenv("WORDPRESS_PASSWORD", "your-password")

# ============================================
# LOGGING CONFIGURATION
# ============================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================
# WORDPRESS API CLIENT
# ============================================

class WordPressMCP:
    """WordPress API client for MCP operations"""
    
    def __init__(self, base_url: str, username: str, password: str):
        """Initialize WordPress client with Basic Auth"""
        self.base_url = base_url.rstrip('/')
        self.api_base = f"{self.base_url}/wp-json/wp/v2"
        self.username = username
        self.password = password
        
        # Create async HTTP client with auth
        self.client = httpx.AsyncClient(
            auth=(username, password),
            timeout=30.0,
            headers={
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
        )
        logger.info(f"WordPress client initialized for {self.base_url}")
    
    async def create_post(
        self,
        title: str,
        content: str,
        excerpt: str = "",
        status: str = "publish"
    ) -> Dict[str, Any]:
        """Create a new WordPress post"""
        try:
            url = f"{self.api_base}/posts"
            payload = {
                "title": title,
                "content": content,
                "excerpt": excerpt,
                "status": status
            }
            
            logger.info(f"Creating post: {title} (status: {status})")
            response = await self.client.post(url, json=payload)
            response.raise_for_status()
            
            post_data = response.json()
            post_id = post_data.get("id")
            post_url = post_data.get("link", "")
            
            logger.info(f"Post created successfully: ID={post_id}, URL={post_url}")
            
            return {
                "success": True,
                "post_id": post_id,
                "url": post_url,
                "message": f"Post '{title}' created successfully",
                "status": status
            }
            
        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP error: {e.response.status_code} - {e.response.text}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
        except Exception as e:
            error_msg = f"Error creating post: {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
    
    async def update_post(
        self,
        post_id: int,
        title: Optional[str] = None,
        content: Optional[str] = None,
        excerpt: Optional[str] = None
    ) -> Dict[str, Any]:
        """Update an existing WordPress post"""
        try:
            url = f"{self.api_base}/posts/{post_id}"
            payload = {}
            
            if title is not None:
                payload["title"] = title
            if content is not None:
                payload["content"] = content
            if excerpt is not None:
                payload["excerpt"] = excerpt
            
            if not payload:
                return {
                    "success": False,
                    "message": "No fields to update"
                }
            
            logger.info(f"Updating post ID={post_id} with fields: {list(payload.keys())}")
            response = await self.client.post(url, json=payload)
            response.raise_for_status()
            
            post_data = response.json()
            post_url = post_data.get("link", "")
            
            logger.info(f"Post updated successfully: ID={post_id}, URL={post_url}")
            
            return {
                "success": True,
                "post_id": post_id,
                "url": post_url,
                "message": f"Post {post_id} updated successfully"
            }
            
        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP error: {e.response.status_code} - {e.response.text}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
        except Exception as e:
            error_msg = f"Error updating post: {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
    
    async def get_posts(
        self,
        per_page: int = 10,
        page: int = 1
    ) -> Dict[str, Any]:
        """Get list of WordPress posts"""
        try:
            url = f"{self.api_base}/posts"
            params = {
                "per_page": min(per_page, 100),  # Max 100
                "page": page
            }
            
            logger.info(f"Fetching posts: per_page={per_page}, page={page}")
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            
            posts = response.json()
            
            # Extract relevant post info
            post_list = []
            for post in posts:
                post_list.append({
                    "id": post.get("id"),
                    "title": post.get("title", {}).get("rendered", ""),
                    "url": post.get("link", ""),
                    "status": post.get("status", ""),
                    "date": post.get("date", "")
                })
            
            logger.info(f"Retrieved {len(post_list)} posts")
            
            return {
                "success": True,
                "posts": post_list,
                "count": len(post_list),
                "message": f"Retrieved {len(post_list)} posts"
            }
            
        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP error: {e.response.status_code} - {e.response.text}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
        except Exception as e:
            error_msg = f"Error fetching posts: {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
    
    async def delete_post(self, post_id: int) -> Dict[str, Any]:
        """Delete a WordPress post"""
        try:
            url = f"{self.api_base}/posts/{post_id}"
            params = {"force": True}  # Permanently delete
            
            logger.info(f"Deleting post ID={post_id}")
            response = await self.client.delete(url, params=params)
            response.raise_for_status()
            
            logger.info(f"Post deleted successfully: ID={post_id}")
            
            return {
                "success": True,
                "post_id": post_id,
                "message": f"Post {post_id} deleted successfully"
            }
            
        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP error: {e.response.status_code} - {e.response.text}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
        except Exception as e:
            error_msg = f"Error deleting post: {str(e)}"
            logger.error(error_msg)
            return {
                "success": False,
                "message": error_msg,
                "error": str(e)
            }
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()
        logger.info("WordPress client closed")

# ============================================
# MCP SERVER
# ============================================

# Create MCP server instance
mcp_server = Server("wordpress-mcp-server")

# Global WordPress client (initialized in lifespan)
wp_client: Optional[WordPressMCP] = None

@mcp_server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """Return available WordPress tools"""
    return [
        Tool(
            name="create_post",
            description="Create a new WordPress post on your site",
            inputSchema={
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Post title"
                    },
                    "content": {
                        "type": "string",
                        "description": "Post content in HTML format"
                    },
                    "excerpt": {
                        "type": "string",
                        "description": "Post excerpt (optional)",
                        "default": ""
                    },
                    "status": {
                        "type": "string",
                        "enum": ["publish", "draft", "private"],
                        "description": "Post status",
                        "default": "publish"
                    }
                },
                "required": ["title", "content"]
            }
        ),
        Tool(
            name="update_post",
            description="Update an existing WordPress post",
            inputSchema={
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to update"
                    },
                    "title": {
                        "type": "string",
                        "description": "New post title (optional)"
                    },
                    "content": {
                        "type": "string",
                        "description": "New post content in HTML (optional)"
                    },
                    "excerpt": {
                        "type": "string",
                        "description": "New post excerpt (optional)"
                    }
                },
                "required": ["post_id"]
            }
        ),
        Tool(
            name="get_posts",
            description="Get list of WordPress posts",
            inputSchema={
                "type": "object",
                "properties": {
                    "per_page": {
                        "type": "integer",
                        "description": "Number of posts to retrieve (1-100)",
                        "default": 10,
                        "minimum": 1,
                        "maximum": 100
                    },
                    "page": {
                        "type": "integer",
                        "description": "Page number for pagination",
                        "default": 1,
                        "minimum": 1
                    }
                }
            }
        ),
        Tool(
            name="delete_post",
            description="Delete a WordPress post permanently",
            inputSchema={
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to delete"
                    }
                },
                "required": ["post_id"]
            }
        )
    ]

@mcp_server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """Handle tool execution"""
    global wp_client
    
    if wp_client is None:
        return [TextContent(
            type="text",
            text=json.dumps({
                "success": False,
                "message": "WordPress client not initialized"
            })
        )]
    
    logger.info(f"Tool called: {name} with arguments: {arguments}")
    
    try:
        if name == "create_post":
            result = await wp_client.create_post(
                title=arguments.get("title"),
                content=arguments.get("content"),
                excerpt=arguments.get("excerpt", ""),
                status=arguments.get("status", "publish")
            )
        elif name == "update_post":
            result = await wp_client.update_post(
                post_id=arguments.get("post_id"),
                title=arguments.get("title"),
                content=arguments.get("content"),
                excerpt=arguments.get("excerpt")
            )
        elif name == "get_posts":
            result = await wp_client.get_posts(
                per_page=arguments.get("per_page", 10),
                page=arguments.get("page", 1)
            )
        elif name == "delete_post":
            result = await wp_client.delete_post(
                post_id=arguments.get("post_id")
            )
        else:
            result = {
                "success": False,
                "message": f"Unknown tool: {name}"
            }
        
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]
        
    except Exception as e:
        logger.error(f"Error executing tool {name}: {str(e)}")
        return [TextContent(
            type="text",
            text=json.dumps({
                "success": False,
                "message": f"Error executing tool: {str(e)}",
                "error": str(e)
            })
        )]

# ============================================
# FASTAPI APPLICATION
# ============================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown"""
    global wp_client
    
    # Startup
    logger.info("Starting WordPress MCP Server...")
    wp_client = WordPressMCP(WORDPRESS_URL, WORDPRESS_USERNAME, WORDPRESS_PASSWORD)
    logger.info("WordPress MCP Server started successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down WordPress MCP Server...")
    if wp_client:
        await wp_client.close()
    logger.info("WordPress MCP Server shut down")

# Create FastAPI app
app = FastAPI(
    title="WordPress MCP SSE Server",
    description="MCP server for managing WordPress posts via ChatGPT",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# ENDPOINTS
# ============================================

@app.get("/")
async def root():
    """Server information"""
    return {
        "name": "WordPress MCP SSE Server",
        "version": "1.0.0",
        "protocol": "MCP over SSE",
        "endpoints": {
            "info": "/",
            "health": "/health",
            "sse": "/sse",
            "mcp": "/mcp"
        },
        "tools": [
            {
                "name": "create_post",
                "description": "Create a new WordPress post"
            },
            {
                "name": "update_post",
                "description": "Update an existing post"
            },
            {
                "name": "get_posts",
                "description": "Get list of posts"
            },
            {
                "name": "delete_post",
                "description": "Delete a post"
            }
        ],
        "configuration": {
            "wordpress_url": WORDPRESS_URL,
            "username": WORDPRESS_USERNAME
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "wordpress-mcp-sse-server"
    }

@app.get("/sse")
async def sse_endpoint(request: Request):
    """SSE endpoint for ChatGPT connection"""
    
    async def event_generator():
        """Generate SSE events"""
        try:
            # Send endpoint URL
            endpoint_url = str(request.url).replace("/sse", "/mcp")
            yield {
                "event": "endpoint",
                "data": json.dumps({"url": endpoint_url})
            }
            
            logger.info(f"SSE connection established, endpoint: {endpoint_url}")
            
            # Send heartbeat every 15 seconds
            while True:
                if await request.is_disconnected():
                    logger.info("SSE client disconnected")
                    break
                
                yield {
                    "event": "heartbeat",
                    "data": json.dumps({"status": "alive"})
                }
                
                await asyncio.sleep(15)
                
        except Exception as e:
            logger.error(f"SSE error: {str(e)}")
    
    return EventSourceResponse(
        event_generator(),
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no"
        }
    )

@app.post("/mcp")
async def mcp_endpoint(request: Request):
    """MCP JSON-RPC endpoint"""
    try:
        body = await request.json()
        method = body.get("method")
        params = body.get("params", {})
        request_id = body.get("id", 1)
        
        logger.info(f"MCP request: method={method}, id={request_id}")
        
        # Handle initialize
        if method == "initialize":
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "wordpress-mcp-server",
                        "version": "1.0.0"
                    }
                }
            }
            return JSONResponse(response)
        
        # Handle tools/list
        elif method == "tools/list":
            tools_list = await handle_list_tools()
            tools_dict = [
                {
                    "name": tool.name,
                    "description": tool.description,
                    "inputSchema": tool.inputSchema
                }
                for tool in tools_list
            ]
            
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "tools": tools_dict
                }
            }
            return JSONResponse(response)
        
        # Handle tools/call
        elif method == "tools/call":
            tool_name = params.get("name")
            arguments = params.get("arguments", {})
            
            result = await handle_call_tool(tool_name, arguments)
            
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": result[0].text
                        }
                    ]
                }
            }
            return JSONResponse(response)
        
        else:
            # Unknown method
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {
                    "code": -32601,
                    "message": f"Method not found: {method}"
                }
            }
            return JSONResponse(response, status_code=400)
            
    except Exception as e:
        logger.error(f"MCP endpoint error: {str(e)}")
        return JSONResponse({
            "jsonrpc": "2.0",
            "id": body.get("id", 1) if body else 1,
            "error": {
                "code": -32603,
                "message": f"Internal error: {str(e)}"
            }
        }, status_code=500)

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    logger.info("="*50)
    logger.info("WordPress MCP SSE Server")
    logger.info("="*50)
    logger.info(f"WordPress URL: {WORDPRESS_URL}")
    logger.info(f"Username: {WORDPRESS_USERNAME}")
    logger.info("="*50)
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
