# SSL 证书配置指南

## 推荐方案：Let's Encrypt 免费证书

Let's Encrypt 是免费的自动化的证书颁发机构 (CA)，提供 90 天有效期的 SSL 证书，支持自动续期。

### 安装 Certbot

#### Ubuntu/Debian

```bash
# 安装 Certbot 和 Nginx 插件
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# 或仅安装 Certbot
sudo apt-get install certbot
```

#### CentOS 7

```bash
# 安装 EPEL 源
sudo yum install epel-release

# 安装 Certbot
sudo yum install certbot python2-certbot-nginx

# 关闭 httpd (如果使用 Apache)
sudo systemctl stop httpd
sudo systemctl disable httpd
```

#### Rocky Linux 8+ / AlmaLinux 8+

```bash
# 安装 Certbot
sudo dnf install certbot python3-certbot-nginx

# 关闭 httpd (如果使用 Apache)
sudo systemctl stop httpd
sudo systemctl disable httpd
```

### 获取证书 (Nginx)

```bash
# 单域名
sudo certbot --nginx -d example.com -d www.example.com

# 多域名 (最多 100 个)
sudo certbot --nginx -d example.com -d www.example.com -d api.example.com

# 仅获取证书 (手动配置)
sudo certbot certonly --webroot -w /var/www/html -d example.com -d www.example.com

# 使用 standalone 模式 (需要停止 Nginx)
sudo certbot certonly --standalone -d example.com -d www.example.com
```

### 获取证书 (Apache)

```bash
# 安装 Apache 插件
sudo apt-get install python3-certbot-apache

# 获取并自动配置 Apache
sudo certbot --apache -d example.com -d www.example.com
```

### Certbot 命令详解

```bash
# 查看帮助
certbot --help all

# 测试续期 (不实际执行)
sudo certbot renew --dry-run

# 强制续期
sudo certbot renew --force-renewal

# 手动续期
sudo certbot renew

# 查看证书
sudo certbot certificates

# 删除证书
sudo certbot delete --cert-name example.com

# 撤销证书
sudo certbot revoke --cert-path /etc/letsencrypt/live/example.com/fullchain.pem
```

## Nginx SSL 配置

### 基本 HTTPS 配置

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    # 强制跳转到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL 证书路径
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS (可选，启用后用户浏览器会强制使用 HTTPS)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    root /var/www/example.com;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # 其他配置...
}
```

### 优化 SSL 配置

```nginx
# SSL 会话缓存
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# 禁用 SSL Session Tickets
ssl_session_tickets off;
```

## Apache SSL 配置

### 基本 HTTPS 配置

```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    # 强制跳转到 HTTPS
    Redirect permanent / https://example.com/
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com

    # SSL 配置
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem

    # SSL 安全配置
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on

    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
</IfModule>
```

## 自动续期配置

Let's Encrypt 证书有效期为 90 天，Certbot 安装后会自动配置定时任务：

```bash
# 查看定时任务
sudo systemctl list-timers | grep certbot

# 查看续期脚本
sudo cat /etc/cron.d/certbot

# 手动添加续期定时任务 (如果没有)
sudo crontab -e

# 每天凌晨 3 点检查并续期
0 3 * * * root certbot renew --quiet --deploy-hook "systemctl reload nginx"
```

### 续期钩子

```bash
# /etc/letsencrypt/renewal/example.com.conf
renew_hook = systemctl reload nginx
```

```bash
# 或使用 --deploy-hook
sudo certbot renew --deploy-hook "systemctl reload nginx"
```

## 证书文件说明

| 文件 | 说明 |
|------|------|
| `fullchain.pem` | 完整证书链 (包含证书和中间证书) |
| `privkey.pem` | 私钥 |
| `chain.pem` | 中间证书链 |
| `cert.pem` | 服务器证书 |

## 证书位置

| 系统 | 路径 |
|------|------|
| Ubuntu/Debian | `/etc/letsencrypt/live/example.com/` |
| CentOS/Rocky/Alma | `/etc/letsencrypt/live/example.com/` |
| 其他 | `/etc/letsencrypt/archive/` |

## SSL 检测工具

```bash
# 使用 SSL Labs 在线检测
# 访问: https://www.ssllabs.com/ssltest/analyze.html?d=example.com

# 本地检测工具
# 安装 testssl.sh
git clone --depth 1 https://github.com/drwetter/testssl.sh.git
cd testssl.sh

# 运行检测
./testssl.sh example.com

# 检测本地服务器
./testssl.sh -P 127.0.0.1:443
```

## 常见问题排查

```bash
# 测试 Nginx 配置
sudo nginx -t

# 测试 Apache 配置
sudo apache2ctl configtest    # Debian
sudo httpd -t                 # CentOS

# 重载配置
sudo systemctl reload nginx
sudo systemctl reload apache2

# 查看证书详细信息
openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -text -noout

# 查看证书过期时间
openssl x509 -in /etc/letsencrypt/live/example.com/fullchain.pem -dates -noout

# 测试 SSL 连接
openssl s_client -connect example.com:443 -servername example.com

# 检查证书链完整性
openssl s_client -connect example.com:443 -showcerts
```

## 商业证书安装 (如有)

```bash
# 如果有商业证书，按以下步骤安装

# 1. 上传证书文件到服务器
scp certificate.crt root@server:/etc/ssl/certs/
scp private.key root@server:/etc/ssl/private/

# 2. 设置权限
chmod 600 /etc/ssl/private/private.key
chmod 644 /etc/ssl/certs/certificate.crt

# 3. 配置 Nginx
# ssl_certificate /etc/ssl/certs/certificate.crt;
# ssl_certificate_key /etc/ssl/private/private.key;

# 4. 重载配置
sudo systemctl reload nginx
```

## HTTP/2 配置

HTTP/2 需要 HTTPS 支持，Nginx 1.13+ 默认支持：

```nginx
server {
    listen 443 ssl http2;  # 启用 HTTP/2
    # ...
}
```

## HTTP/3 (QUIC) 配置

```nginx
server {
    listen 443 ssl;
    listen 443 quic reuseport;

    # HTTP/3 相关头
    add_header alt-svc 'h3=":443"; ma=86400';

    # ...
}
```

## CAA 记录配置

CAA 记录可以指定哪些 CA 可以为你的域名颁发证书：

```
# DNS CAA 记录
example.com.  IN  CAA  0 issue "letsencrypt.org"
example.com.  IN  CAA  0 issuewild "letsencrypt.org"
example.com.  IN  CAA  0 iodef "mailto:admin@example.com"
```
