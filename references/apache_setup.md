# Apache 安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install apache2` |
| CentOS/Rocky/AlmaLinux | `yum install httpd` |

## 安装步骤

### Ubuntu/Debian

```bash
# 更新软件源
sudo apt-get update

# 安装 Apache
sudo apt-get install apache2

# 启动并设置开机自启
sudo systemctl start apache2
sudo systemctl enable apache2

# 检查状态
sudo systemctl status apache2
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# 安装 Apache
sudo yum install httpd

# 启动并设置开机自启
sudo systemctl start httpd
sudo systemctl enable httpd

# 检查状态
sudo systemctl status httpd

# 防火墙开放端口
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/apache2/apache2.conf` | 主配置文件 (Debian) |
| `/etc/httpd/conf/httpd.conf` | 主配置文件 (CentOS) |
| `/etc/apache2/sites-available/` | 可用站点配置 (Debian) |
| `/etc/apache2/sites-enabled/` | 已启用站点配置 (Debian) |
| `/etc/apache2/conf-available/` | 可用配置 (Debian) |
| `/etc/httpd/conf.d/` | 配置目录 (CentOS) |
| `/var/log/apache2/` | 日志目录 (Debian) |
| `/var/log/httpd/` | 日志目录 (CentOS) |
| `/var/www/html/` | 默认网站根目录 |

## 创建站点配置

### 示例：启用站点 (Debian)

```bash
# 创建站点配置文件
sudo nano /etc/apache2/sites-available/example.com.conf

# 启用站点
sudo a2ensite example.com.conf

# 禁用默认站点
sudo a2dissite 000-default.conf

# 重载配置
sudo systemctl reload apache2
```

### 示例：PHP 站点配置

```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com

    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/example.com_error.log
    CustomLog ${APACHE_LOG_DIR}/example.com_access.log combined
</VirtualHost>
```

### 示例：启用 mod_rewrite

```bash
# 启用 rewrite 模块
sudo a2enmod rewrite

# 启用其他常用模块
sudo a2enmod ssl
sudo a2enmod headers
sudo a2enmod proxy
sudo a2enmod proxy_http

# 重载 Apache
sudo systemctl reload apache2
```

### 示例：Node.js 反向代理

```apache
<VirtualHost *:80>
    ServerName nodeapp.example.com

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "http"
</VirtualHost>
```

## 常用命令

```bash
# 检查配置语法
sudo apache2ctl configtest        # Debian
sudo httpd -t                     # CentOS

# 重载配置
sudo systemctl reload apache2      # Debian
sudo systemctl reload httpd       # CentOS

# 重启服务
sudo systemctl restart apache2    # Debian
sudo systemctl restart httpd      # CentOS

# 查看版本
apache2 -v                        # Debian
httpd -v                          # CentOS
```

## SSL 配置 (配合 Let's Encrypt)

```apache
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem

    <Directory /var/www/example.com>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
</IfModule>
```

## 性能优化

```apache
# /etc/apache2/mods-available/mpm_prefork.conf (Debian)
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild 3000
</IfModule>

# 启用 gzip 压缩
sudo a2enmod deflate
```
