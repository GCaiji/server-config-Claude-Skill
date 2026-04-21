# Nginx 安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install nginx` |
| CentOS/Rocky/AlmaLinux | `yum install nginx` 或 `dnf install nginx` |

## 安装步骤

### Ubuntu/Debian

```bash
# 更新软件源
sudo apt-get update

# 安装 Nginx
sudo apt-get install nginx

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx

# 检查状态
sudo systemctl status nginx
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# 安装 EPEL 源 (CentOS 7)
sudo yum install epel-release

# 安装 Nginx
sudo yum install nginx

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx

# 检查状态
sudo systemctl status nginx
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/nginx/nginx.conf` | 主配置文件 |
| `/etc/nginx/conf.d/` | 自定义配置文件目录 |
| `/etc/nginx/sites-available/` | 可用站点配置 (Debian系) |
| `/etc/nginx/sites-enabled/` | 已启用站点配置 (Debian系) |
| `/var/log/nginx/` | 日志目录 |
| `/var/www/html/` | 默认网站根目录 |

## 创建站点配置

### 示例：PHP 站点 (WordPress)

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/example.com;
    index index.php index.html index.htm;

    # 日志
    access_log /var/log/nginx/example.com.access.log;
    error_log /var/log/nginx/example.com.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM 配置
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # WordPress 伪静态
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
}
```

### 示例：Node.js 站点 (反向代理)

```nginx
server {
    listen 80;
    server_name nodeapp.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 常用命令

```bash
# 检查配置语法
sudo nginx -t

# 重载配置
sudo systemctl reload nginx

# 重启服务
sudo systemctl restart nginx

# 查看版本
nginx -v

# 查看编译信息
nginx -V
```

## 性能优化建议

```nginx
# nginx.conf 中的 worker 配置
worker_processes auto;
worker_connections 2048;
multi_accept on;
use epoll;

# Gzip 压缩
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;
```

## SSL 配置 (配合 Let's Encrypt)

```nginx
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```
