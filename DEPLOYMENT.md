# 🚀 WordPress MCP Server - Production Развертывание

**Руководство по развертыванию на 7 платформах**

---

## 📑 Содержание

1. [Production Checklist](#production-checklist)
2. [DigitalOcean](#1-digitalocean)
3. [AWS EC2](#2-aws-ec2)
4. [Google Cloud Platform](#3-google-cloud-platform)
5. [Microsoft Azure](#4-microsoft-azure)
6. [Linode](#5-linode)
7. [Vultr](#6-vultr)
8. [Hetzner Cloud](#7-hetzner-cloud)
9. [Docker Deployment](#docker-deployment)
10. [Kubernetes Deployment](#kubernetes-deployment)
11. [Мониторинг и логирование](#мониторинг-и-логирование)
12. [Backup и Recovery](#backup-и-recovery)
13. [Security Hardening](#security-hardening)

---

## Production Checklist

Перед развертыванием в production убедитесь:

### Обязательно:
- [ ] ✅ Environment variables для credentials (не hardcode!)
- [ ] ✅ API Key аутентификация на /mcp endpoint
- [ ] ✅ Rate limiting настроен
- [ ] ✅ CORS ограничен конкретными origins
- [ ] ✅ HTTPS с валидным SSL сертификатом
- [ ] ✅ Firewall правила настроены
- [ ] ✅ systemd сервис для автозапуска
- [ ] ✅ Логирование в файл и syslog
- [ ] ✅ Мониторинг (health checks)
- [ ] ✅ Backup стратегия
- [ ] ✅ Error tracking (Sentry)
- [ ] ✅ Application Password вместо основного пароля

### Рекомендуется:
- [ ] ⚙️ Nginx reverse proxy
- [ ] ⚙️ Let's Encrypt SSL
- [ ] ⚙️ Prometheus метрики
- [ ] ⚙️ Grafana dashboards
- [ ] ⚙️ ELK/Loki для логов
- [ ] ⚙️ Redis для кеширования
- [ ] ⚙️ CI/CD pipeline
- [ ] ⚙️ Load balancer (при масштабировании)
- [ ] ⚙️ Database backups
- [ ] ⚙️ Disaster recovery план

---

## 1. DigitalOcean

### Создание Droplet

**Шаг 1:** Создайте Droplet
```
- Image: Ubuntu 22.04 LTS
- Plan: Basic ($6/month — 1 GB RAM, 1 CPU)
- Datacenter: Выберите ближайший к WordPress
- Authentication: SSH keys (рекомендуется)
```

**Шаг 2:** Подключитесь по SSH
```bash
ssh root@your-droplet-ip
```

**Шаг 3:** Базовая настройка
```bash
# Обновление системы
apt update && apt upgrade -y

# Создание пользователя (не используйте root)
adduser mcp
usermod -aG sudo mcp

# Настройка firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Переключитесь на нового пользователя
su - mcp
```

### Установка проекта

```bash
# Клонирование проекта
cd ~
mkdir wordpress-mcp && cd wordpress-mcp

# Копирование файлов (через scp с локальной машины)
# scp *.py *.txt *.sh *.md mcp@your-ip:~/wordpress-mcp/

# Настройка credentials (используйте .env)
nano .env
```

**.env файл:**
```env
WORDPRESS_URL=https://your-site.com/
WORDPRESS_USERNAME=admin
WORDPRESS_PASSWORD=your-app-password
MCP_API_KEY=your-secure-random-key-32-chars
```

**Обновите mcp_sse_server.py для использования .env:**
```python
import os
from dotenv import load_dotenv

load_dotenv()

WORDPRESS_URL = os.getenv("WORDPRESS_URL")
WORDPRESS_USERNAME = os.getenv("WORDPRESS_USERNAME")
WORDPRESS_PASSWORD = os.getenv("WORDPRESS_PASSWORD")
```

**Запуск установки:**
```bash
chmod +x install.sh
sudo ./install.sh
```

### Настройка Nginx + SSL

```bash
# Установка Nginx
sudo apt install nginx certbot python3-certbot-nginx -y

# Конфигурация Nginx
sudo nano /etc/nginx/sites-available/mcp
```

**/etc/nginx/sites-available/mcp:**
```nginx
server {
    listen 80;
    server_name mcp.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # SSE support
    location /sse {
        proxy_pass http://localhost:8000/sse;
        proxy_http_version 1.1;
        proxy_set_header Connection '';
        proxy_buffering off;
        proxy_cache off;
        chunked_transfer_encoding off;
    }
}
```

**Активация:**
```bash
sudo ln -s /etc/nginx/sites-available/mcp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**SSL сертификат:**
```bash
sudo certbot --nginx -d mcp.yourdomain.com
```

### Мониторинг

```bash
# Просмотр логов
sudo journalctl -u wordpress-mcp-server -f

# Статус сервиса
sudo systemctl status wordpress-mcp-server

# Диагностика
./check_status.sh
```

---

## 2. AWS EC2

### Создание EC2 Instance

**Шаг 1:** AWS Console → EC2 → Launch Instance

```
- Name: wordpress-mcp-server
- AMI: Ubuntu Server 22.04 LTS (Free tier eligible)
- Instance type: t2.micro (1 GB RAM, 1 vCPU) или t3.small
- Key pair: Создайте или выберите существующий
- Network settings:
  - Allow SSH (22)
  - Allow HTTP (80)
  - Allow HTTPS (443)
- Storage: 8 GB (достаточно)
```

**Шаг 2:** Подключение
```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@your-ec2-ip
```

**Шаг 3:** Базовая настройка
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install python3 python3-pip python3-venv git -y
```

### Security Groups

**Настройте Security Group:**
```
Inbound Rules:
- SSH (22) from Your IP
- HTTP (80) from Anywhere (0.0.0.0/0)
- HTTPS (443) from Anywhere (0.0.0.0/0)
- Custom TCP (8000) from Localhost (опционально для debug)

Outbound Rules:
- All traffic to Anywhere
```

### Elastic IP (опционально)

Для постоянного IP:
```
EC2 → Elastic IPs → Allocate Elastic IP address
→ Associate Elastic IP address → Выберите ваш instance
```

### Route 53 (DNS)

Если используете домен:
```
Route 53 → Hosted zones → Create hosted zone
→ Create record:
  - Name: mcp
  - Type: A
  - Value: Your Elastic IP
```

### Установка проекта

Аналогично DigitalOcean (см. выше).

### Auto Scaling (опционально)

Для высокой нагрузки:

**1. Создайте AMI:**
```bash
# После настройки instance
EC2 → Instances → Actions → Image and templates → Create image
```

**2. Launch Template:**
```
EC2 → Launch Templates → Create launch template
- Use your AMI
- t3.small instance type
- Same security group
```

**3. Auto Scaling Group:**
```
EC2 → Auto Scaling Groups → Create Auto Scaling group
- Min: 1
- Desired: 2
- Max: 5
- Target tracking: Average CPU 70%
```

---

## 3. Google Cloud Platform

### Создание VM Instance

**Через gcloud CLI:**
```bash
gcloud compute instances create wordpress-mcp-server \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --tags=http-server,https-server
```

**Или через Console:**
```
Compute Engine → VM instances → Create Instance
- Name: wordpress-mcp-server
- Region: us-central1
- Machine type: e2-micro (0.25-2 vCPU, 1 GB RAM)
- Boot disk: Ubuntu 22.04 LTS, 10 GB
- Firewall: Allow HTTP and HTTPS traffic
```

### Firewall Rules

```bash
# Создание firewall правил
gcloud compute firewall-rules create allow-mcp \
  --allow tcp:8000 \
  --source-ranges 0.0.0.0/0 \
  --target-tags mcp-server

gcloud compute firewall-rules create allow-ssh \
  --allow tcp:22 \
  --source-ranges YOUR_IP/32
```

### SSH подключение

```bash
gcloud compute ssh wordpress-mcp-server --zone=us-central1-a
```

### Static IP

```bash
# Резервирование Static IP
gcloud compute addresses create mcp-static-ip --region=us-central1

# Назначение VM
gcloud compute instances add-access-config wordpress-mcp-server \
  --zone=us-central1-a \
  --address $(gcloud compute addresses describe mcp-static-ip \
  --region=us-central1 --format="get(address)")
```

### Cloud DNS

```bash
# Создание зоны
gcloud dns managed-zones create mcp-zone \
  --dns-name=yourdomain.com. \
  --description="MCP DNS Zone"

# Добавление A record
gcloud dns record-sets create mcp.yourdomain.com. \
  --zone=mcp-zone \
  --type=A \
  --ttl=300 \
  --rrdatas=YOUR_STATIC_IP
```

### Установка

Аналогично DigitalOcean.

### Load Balancer (опционально)

Для высокой доступности:
```
Network Services → Load balancing → Create load balancer
→ HTTP(S) Load Balancing
→ Backend: Instance group with MCP servers
→ Frontend: HTTPS with SSL certificate
```

---

## 4. Microsoft Azure

### Создание VM

**Azure CLI:**
```bash
az vm create \
  --resource-group mcp-resources \
  --name wordpress-mcp-vm \
  --image UbuntuLTS \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys
```

**Или через Portal:**
```
Virtual Machines → Create
- Basics:
  - Resource group: Create new "mcp-resources"
  - Virtual machine name: wordpress-mcp-vm
  - Image: Ubuntu Server 22.04 LTS
  - Size: Standard_B1s (1 vCPU, 1 GB RAM)
  - Authentication: SSH public key
- Networking:
  - Public IP: Yes
  - NIC network security group: Basic
  - Public inbound ports: SSH (22), HTTP (80), HTTPS (443)
```

### Network Security Group

```bash
# Создание NSG правил
az network nsg rule create \
  --resource-group mcp-resources \
  --nsg-name wordpress-mcp-vmNSG \
  --name AllowHTTP \
  --priority 1001 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow

az network nsg rule create \
  --resource-group mcp-resources \
  --nsg-name wordpress-mcp-vmNSG \
  --name AllowHTTPS \
  --priority 1002 \
  --destination-port-ranges 443 \
  --protocol Tcp \
  --access Allow
```

### SSH подключение

```bash
ssh azureuser@your-azure-vm-ip
```

### Static Public IP

```bash
az network public-ip update \
  --resource-group mcp-resources \
  --name wordpress-mcp-vmPublicIP \
  --allocation-method Static
```

### Azure DNS

```bash
# Создание DNS зоны
az network dns zone create \
  --resource-group mcp-resources \
  --name yourdomain.com

# A record
az network dns record-set a add-record \
  --resource-group mcp-resources \
  --zone-name yourdomain.com \
  --record-set-name mcp \
  --ipv4-address YOUR_PUBLIC_IP
```

### Установка

Аналогично DigitalOcean.

---

## 5. Linode

### Создание Linode

**Через CLI:**
```bash
linode-cli linodes create \
  --type g6-nanode-1 \
  --region us-east \
  --image linode/ubuntu22.04 \
  --label wordpress-mcp-server \
  --root_pass YOUR_ROOT_PASSWORD
```

**Или через Cloud Manager:**
```
Linodes → Create Linode
- Image: Ubuntu 22.04 LTS
- Region: Выберите ближайший
- Linode Plan: Nanode 1 GB ($5/month)
- Root Password: Создайте надежный
```

### Firewall

```bash
# Cloud Manager → Firewalls → Create Firewall
Rules:
- Inbound: SSH (22), HTTP (80), HTTPS (443)
- Outbound: All TCP/UDP
- Apply to: wordpress-mcp-server
```

### SSH

```bash
ssh root@your-linode-ip
```

### Установка

Аналогично DigitalOcean.

---

## 6. Vultr

### Создание Instance

```
Deploy → Compute
- Server Location: Выберите ближайший
- Server Type: Cloud Compute - 55GB NVMe ($6/month)
- Server Image: Ubuntu 22.04 x64
- Server Hostname: wordpress-mcp-server
```

### Firewall

```
Network → Firewall → Add Firewall Group
Rules:
- Protocol: TCP, Port: 22, Source: Your IP
- Protocol: TCP, Port: 80, Source: Anywhere
- Protocol: TCP, Port: 443, Source: Anywhere

Attach to: wordpress-mcp-server
```

### SSH

```bash
ssh root@your-vultr-ip
```

### Установка

Аналогично DigitalOcean.

---

## 7. Hetzner Cloud

### Создание Server

**Через hcloud CLI:**
```bash
hcloud server create \
  --name wordpress-mcp-server \
  --type cx11 \
  --image ubuntu-22.04 \
  --location nbg1
```

**Или через Cloud Console:**
```
Servers → Add Server
- Location: Nuremberg (or Falkenstein, Helsinki)
- Image: Ubuntu 22.04
- Type: CX11 (1 vCPU, 2 GB RAM) — €4.15/month
- Networking: IPv4
- SSH Keys: Add yours
```

### Firewall

```bash
# Создание firewall
hcloud firewall create --name mcp-firewall

# Правила
hcloud firewall add-rule mcp-firewall \
  --direction in --protocol tcp --port 22 --source-ips 0.0.0.0/0

hcloud firewall add-rule mcp-firewall \
  --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0

hcloud firewall add-rule mcp-firewall \
  --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0

# Apply к серверу
hcloud firewall apply-to-resource mcp-firewall \
  --type server --server wordpress-mcp-server
```

### SSH

```bash
ssh root@your-hetzner-ip
```

### Floating IP (опционально)

```bash
hcloud floating-ip create \
  --type ipv4 \
  --name mcp-floating-ip \
  --home-location nbg1

hcloud floating-ip assign MCP_FLOATING_IP_ID wordpress-mcp-server
```

### Установка

Аналогично DigitalOcean.

---

## Docker Deployment

### Создание Dockerfile

**Dockerfile:**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY requirements.txt .
COPY mcp_sse_server.py .

# Install Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 8000

# Environment variables
ENV WORDPRESS_URL=""
ENV WORDPRESS_USERNAME=""
ENV WORDPRESS_PASSWORD=""

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Run server
CMD ["python", "mcp_sse_server.py"]
```

### Docker Compose

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  mcp-server:
    build: .
    container_name: wordpress-mcp-server
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - WORDPRESS_URL=${WORDPRESS_URL}
      - WORDPRESS_USERNAME=${WORDPRESS_USERNAME}
      - WORDPRESS_PASSWORD=${WORDPRESS_PASSWORD}
    env_file:
      - .env
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - mcp-network

networks:
  mcp-network:
    driver: bridge
```

### Запуск

```bash
# Build
docker-compose build

# Run
docker-compose up -d

# Logs
docker-compose logs -f

# Stop
docker-compose down
```

### Docker Hub

```bash
# Build and tag
docker build -t your-username/wordpress-mcp-server:1.0.0 .

# Push
docker push your-username/wordpress-mcp-server:1.0.0

# Pull and run на другом сервере
docker pull your-username/wordpress-mcp-server:1.0.0
docker run -d -p 8000:8000 \
  -e WORDPRESS_URL=https://your-site.com/ \
  -e WORDPRESS_USERNAME=admin \
  -e WORDPRESS_PASSWORD=password \
  your-username/wordpress-mcp-server:1.0.0
```

---

## Kubernetes Deployment

### Deployment YAML

**k8s/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-mcp-server
  labels:
    app: wordpress-mcp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress-mcp
  template:
    metadata:
      labels:
        app: wordpress-mcp
    spec:
      containers:
      - name: mcp-server
        image: your-username/wordpress-mcp-server:1.0.0
        ports:
        - containerPort: 8000
        env:
        - name: WORDPRESS_URL
          valueFrom:
            secretKeyRef:
              name: wordpress-credentials
              key: url
        - name: WORDPRESS_USERNAME
          valueFrom:
            secretKeyRef:
              name: wordpress-credentials
              key: username
        - name: WORDPRESS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: wordpress-credentials
              key: password
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Service YAML

**k8s/service.yaml:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress-mcp-service
spec:
  type: LoadBalancer
  selector:
    app: wordpress-mcp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

### Secret YAML

**k8s/secret.yaml:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-credentials
type: Opaque
stringData:
  url: "https://your-site.com/"
  username: "admin"
  password: "your-app-password"
```

### Ingress (опционально)

**k8s/ingress.yaml:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress-mcp-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - mcp.yourdomain.com
    secretName: mcp-tls
  rules:
  - host: mcp.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: wordpress-mcp-service
            port:
              number: 80
```

### Развертывание

```bash
# Создание Secret
kubectl apply -f k8s/secret.yaml

# Deployment
kubectl apply -f k8s/deployment.yaml

# Service
kubectl apply -f k8s/service.yaml

# Ingress (если используется)
kubectl apply -f k8s/ingress.yaml

# Проверка
kubectl get pods
kubectl get services
kubectl logs -f deployment/wordpress-mcp-server
```

---

## Мониторинг и логирование

### Prometheus + Grafana

**1. Добавьте метрики в код:**

```python
from prometheus_client import Counter, Histogram, generate_latest, REGISTRY

# Метрики
requests_total = Counter('mcp_requests_total', 'Total requests', ['method', 'endpoint'])
request_duration = Histogram('mcp_request_duration_seconds', 'Request duration')
errors_total = Counter('mcp_errors_total', 'Total errors')

@app.get("/metrics")
async def metrics():
    from prometheus_client import generate_latest
    return Response(generate_latest(REGISTRY), media_type="text/plain")
```

**2. Prometheus config:**

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'wordpress-mcp'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

**3. Grafana Dashboard:**

Импортируйте готовый dashboard или создайте свой с метриками:
- Request rate (req/sec)
- Error rate
- Response time (p50, p95, p99)
- Active connections

### ELK Stack (Elasticsearch, Logstash, Kibana)

**Filebeat config:**

```yaml
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/wordpress-mcp/*.log
  fields:
    service: wordpress-mcp
    
output.logstash:
  hosts: ["localhost:5044"]
```

### Sentry (Error Tracking)

```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastAPIIntegration

sentry_sdk.init(
    dsn="https://your-sentry-dsn",
    integrations=[FastAPIIntegration()],
    traces_sample_rate=0.1
)
```

---

## Backup и Recovery

### Backup стратегия:

**1. Конфигурация (.env файл):**
```bash
# Ежедневный backup
0 2 * * * tar -czf /backup/mcp-config-$(date +\%Y\%m\%d).tar.gz /opt/wordpress-mcp-server/.env
```

**2. Логи:**
```bash
# Архивирование логов (еженедельно)
0 3 * * 0 tar -czf /backup/mcp-logs-$(date +\%Y\%m\%d).tar.gz /var/log/wordpress-mcp/
```

**3. База данных (если есть):**
```bash
# Backup PostgreSQL/MySQL
0 1 * * * pg_dump wordpress_mcp > /backup/db-$(date +\%Y\%m\%d).sql
```

### Disaster Recovery:

**1. Документируйте:**
- Все конфигурации
- Переменные окружения
- Зависимости (requirements.txt)
- Firewall правила

**2. Создайте скрипт восстановления:**

```bash
#!/bin/bash
# restore.sh

# Восстановление конфигурации
tar -xzf backup-config.tar.gz -C /

# Переустановка зависимостей
cd /opt/wordpress-mcp-server
source venv/bin/activate
pip install -r requirements.txt

# Перезапуск сервиса
sudo systemctl restart wordpress-mcp-server
```

---

## Security Hardening

### 1. System Level:

```bash
# Обновления безопасности
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban

# SSH hardening
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes
sudo systemctl restart sshd
```

### 2. Application Level:

**Добавьте API Key auth:**

```python
from fastapi import Header, HTTPException

API_KEY = os.getenv("MCP_API_KEY")

@app.post("/mcp")
async def mcp_endpoint(
    request: Request,
    x_api_key: str = Header(None)
):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")
    # ... rest of code
```

**Rate limiting:**

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/mcp")
@limiter.limit("10/minute")
async def mcp_endpoint(request: Request):
    # ...
```

### 3. Network Level:

```bash
# IP whitelisting (если возможно)
sudo ufw allow from CHATGPT_IP to any port 8000

# HTTPS only
sudo ufw deny 8000/tcp  # Закрыть HTTP port
# Используйте Nginx proxy с SSL
```

---

## 🎉 Готово!

Выберите платформу и следуйте инструкциям. Для большинства случаев достаточно **DigitalOcean** или **Linode** — они просты и доступны.

**Для enterprise:** AWS, GCP, Azure с auto-scaling и load balancing.

**Для контейнеров:** Docker + Kubernetes для максимальной гибкости.

---

**Вопросы?** → [FAQ.md](FAQ.md)

**Проблемы?** → [SETUP_GUIDE.md](SETUP_GUIDE.md) Troubleshooting
