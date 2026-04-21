# API 网关与 Nginx 反向代理配置指南

## 概述

本文档解决一个常见问题：**前端通过 Nginx 访问后端 API 时出现 404 错误**。

这个问题通常由以下原因导致：

1. Nginx `proxy_pass` 端口与后端服务端口不匹配
2. Nginx 配置的路径与后端 API 路径不匹配
3. 后端服务未正确启动或端口被占用
4. Nginx 配置未生效或未重载
5. 防火墙阻止了内部端口

---

## 排查流程

```
┌─────────────────────────────────────────────────────────────┐
│              前端 API 请求 404                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: 检查后端服务是否运行                              │
│  ss -tlnp | grep :端口号                                    │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
           运行中                          未运行
              │                               │
              ▼                               ▼
    ┌─────────────────┐            ┌─────────────────────┐
    │ Step 2: 检查     │            │ 启动后端服务         │
    │ Nginx 配置       │            │ 检查端口占用         │
    └─────────────────┘            └─────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 3: 检查 proxy_pass 配置                              │
│  后端端口 == Nginx proxy_pass 端口？                       │
└─────────────────────────────────────────────────────────────┘
              │
              ├──────────────────┬──────────────────┐
              ▼                  ▼                  ▼
            匹配                不匹配            不确定
              │                  │                  │
              ▼                  ▼                  ▼
    ┌─────────────────┐  ┌──────────────┐  ┌─────────────────┐
    │ Step 4: 检查     │  │ 修改 Nginx   │  │ 重新部署后端   │
    │ 路径配置        │  │ 配置         │  │ 并重启         │
    └─────────────────┘  └──────────────┘  └─────────────────┘
```

---

## Step 1: 检查后端服务状态

```bash
# 检查端口是否被监听
ss -tlnp | grep :8082

# 如果服务在 Docker 中，检查容器状态
docker ps | grep 后端容器名

# 检查后端进程
ps aux | grep 服务名

# 查看后端日志
journalctl -u 服务名 --no-pager -n 50
pm2 logs 服务名
docker logs 容器名
```

**正常输出示例：**
```
tcp LISTEN 0 128 *:8082 *:* users:(("yw_back",pid=1234,fd=3))
```

**异常：端口未监听** → 后端服务未启动

---

## Step 2: 检查 Nginx 配置

### 查看所有 Nginx 配置

```bash
# 查看 Nginx 主配置
cat /etc/nginx/nginx.conf

# 查看所有启用站点
ls -la /etc/nginx/sites-enabled/
ls -la /etc/nginx/conf.d/

# 查看站点配置
cat /etc/nginx/sites-enabled/你的站点.conf
```

### 常见问题 1: proxy_pass 端口错误

```nginx
# 错误示例：proxy_pass 端口与服务实际端口不一致
server {
    listen 80;
    server_name api.example.com;

    # 后端服务在 8082 端口
    # 但 proxy_pass 写成了 8080
    location /api/ {
        proxy_pass http://127.0.0.1:8080;  # 错误！
    }
}
```

```nginx
# 正确示例
server {
    listen 80;
    server_name api.example.com;

    location /api/ {
        # 确保端口与后端服务一致
        proxy_pass http://127.0.0.1:8082;
    }
}
```

### 常见问题 2: 路径不匹配

```nginx
# 场景：后端 API 路径是 /api/v1/game
#       前端请求路径是 /api/v1/game

# 错误示例：尾部没有 / 导致路径拼接错误
location /api/ {
    proxy_pass http://127.0.0.1:8082;  # 缺少 /
    # 实际请求会变成 /api//api/v1/game
}

# 正确示例 1：使用尾部 /
location /api/ {
    proxy_pass http://127.0.0.1:8082/;
    # 请求 /api/v1/game → 代理到 /v1/game
}

# 正确示例 2：精确匹配路径
location /api/v1/ {
    proxy_pass http://127.0.0.1:8082/api/v1/;
}

# 正确示例 3：使用变量保留原始路径
location /api/ {
    proxy_pass http://127.0.0.1:8082;
    # 请求 /api/v1/game → 代理到 /api/v1/game
}
```

### 常见问题 3: 缺少必要的 proxy_set_header

```nginx
# 完整示例
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:8082;

        # 关键配置！
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
    }
}
```

### 常见问题 4: 后端有多个端口，Nginx 只代理了一个

```nginx
# 如果后端服务使用多个端口
# 服务A: 8082, 服务B: 8083, 服务C: 8084

# 错误示例：只代理一个端口
location / {
    proxy_pass http://127.0.0.1:8082;
}

# 正确示例：按路径分配
location /api-a/ {
    proxy_pass http://127.0.0.1:8082;
}

location /api-b/ {
    proxy_pass http://127.0.0.1:8083;
}

location /api-c/ {
    proxy_pass http://127.0.0.1:8084;
}
```

---

## Step 3: 测试 Nginx 配置

```bash
# 检查配置语法
sudo nginx -t

# 重新加载配置
sudo systemctl reload nginx

# 如果修改了主配置文件，重启
sudo systemctl restart nginx
```

---

## Step 4: 本地测试 API

```bash
# 直接访问后端（绕过 Nginx）
curl -v http://127.0.0.1:8082/health

# 检查返回状态码
curl -I http://127.0.0.1:8082/health

# 测试具体 API
curl -X POST http://127.0.0.1:8082/api/v1/game/rooms \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

---

## Step 5: 通过 Nginx 测试

```bash
# 通过 Nginx 访问
curl -v http://localhost/api/v1/health

# 检查 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log

# 检查 Nginx 访问日志
sudo tail -f /var/log/nginx/access.log
```

---

## 常见配置模板

### 模板 1: 单后端服务

```nginx
server {
    listen 80;
    server_name your-domain.com;

    root /var/www/your-frontend;
    index index.html;

    # 前端静态文件
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 模板 2: 多后端服务

```nginx
# 后端 A 服务
upstream backend_a {
    server 127.0.0.1:8082;
}

# 后端 B 服务
upstream backend_b {
    server 127.0.0.1:8083;
}

server {
    listen 80;
    server_name api.your-domain.com;

    # 主站 API (端口 8082)
    location / {
        proxy_pass http://backend_a;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # 管理后台 API (端口 8083)
    location /admin/ {
        proxy_pass http://backend_b;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 模板 3: WebSocket 支持

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;

        # WebSocket 支持
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 其他必要头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 模板 4: HTTPS 配置

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP 跳转 HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

---

## 一键排查脚本

```bash
#!/bin/bash
# nginx_api_debug.sh - API 404 排查脚本

PORT=${1:-8082}
NGINX_LOG="/var/log/nginx/error.log"

echo "=========================================="
echo "         Nginx API 404 排查脚本"
echo "=========================================="
echo ""

# Step 1: 检查后端服务
echo "[1/5] 检查后端服务 (端口: $PORT)"
if ss -tlnp | grep -q ":$PORT"; then
    echo "  ✓ 端口 $PORT 正在监听"
    ss -tlnp | grep ":$PORT"
else
    echo "  ✗ 端口 $PORT 未监听 - 后端服务可能未启动"
fi
echo ""

# Step 2: 检查 Nginx 配置
echo "[2/5] 检查 Nginx 配置语法"
if sudo nginx -t 2>&1 | grep -q "syntax is ok"; then
    echo "  ✓ Nginx 配置语法正确"
else
    echo "  ✗ Nginx 配置有语法错误"
    sudo nginx -t
fi
echo ""

# Step 3: 检查 proxy_pass 配置
echo "[3/5] 检查 proxy_pass 配置"
PROXY_COUNT=$(sudo grep -r "proxy_pass" /etc/nginx/ 2>/dev/null | wc -l)
echo "  找到 $PROXY_COUNT 个 proxy_pass 配置"

# 显示所有 proxy_pass
sudo grep -rh "proxy_pass" /etc/nginx/ 2>/dev/null | while read line; do
    echo "    - $line"
done
echo ""

# Step 4: 测试直接访问后端
echo "[4/5] 测试直接访问后端"
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$PORT/health 2>/dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo "  ✓ 后端服务正常响应 (HTTP $RESPONSE)"
    else
        echo "  ✗ 后端服务响应异常 (HTTP $RESPONSE)"
    fi
else
    echo "  ! curl 未安装，跳过测试"
fi
echo ""

# Step 5: 检查 Nginx 日志
echo "[5/5] 最近 Nginx 错误日志"
if [ -f "$NGINX_LOG" ]; then
    echo "  最近 10 条错误:"
    sudo tail -10 "$NGINX_LOG" | while read line; do
        echo "    $line"
    done
else
    echo "  ! 日志文件不存在"
fi
echo ""

echo "=========================================="
echo "              排查完成"
echo "=========================================="
echo ""
echo "建议操作:"
echo "1. 如果端口未监听 → 启动后端服务"
echo "2. 如果配置语法错误 → 修复 /etc/nginx/"
echo "3. 如果后端响应异常 → 检查后端日志"
echo "4. 重载配置: sudo systemctl reload nginx"
```

---

## 排查检查清单

- [ ] 后端服务正在运行
- [ ] 后端服务端口与 Nginx proxy_pass 端口一致
- [ ] Nginx 配置语法正确 (`nginx -t`)
- [ ] Nginx 配置已重载 (`systemctl reload nginx`)
- [ ] 直接访问后端 API 正常 (`curl localhost:端口`)
- [ ] 通过 Nginx 访问 API 正常
- [ ] 前端请求路径与后端 API 路径匹配
- [ ] 防火墙允许内部通信

---

## 快速修复命令

```bash
# 1. 重载 Nginx 配置
sudo systemctl reload nginx

# 2. 重启 Nginx
sudo systemctl restart nginx

# 3. 检查端口占用
ss -tlnp | grep :8082

# 4. 查看 Nginx 错误日志
sudo tail -50 /var/log/nginx/error.log

# 5. 测试 API
curl -v http://127.0.0.1:8082/health
```
