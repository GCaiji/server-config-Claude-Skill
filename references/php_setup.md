# PHP 环境安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install php` |
| CentOS/Rocky/AlmaLinux | `yum install php` 或 `dnf install php` |

## 安装 PHP

### Ubuntu 22.04+

```bash
# 安装 PHP 及常用扩展
sudo apt-get update
sudo apt-get install php php-cli php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip

# 查看 PHP 版本
php -v

# 查看已安装的模块
php -m
```

### Ubuntu 20.04

```bash
# 添加 PPA 获取最新 PHP
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update

# 安装 PHP 8.1
sudo apt-get install php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip
```

### CentOS 7

```bash
# 安装 EPEL 和 Remi 源
sudo yum install epel-release
sudo yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum install yum-utils
sudo yum-config-manager --enable remi-php81

# 安装 PHP 8.1
sudo yum install php php-fpm php-mysqlnd php-curl php-gd php-mbstring php-xml php-zip php-pecl-zip
```

### Rocky Linux 8+ / AlmaLinux 8+

```bash
# 安装 AppStream (Rocky/Alma 默认带 PHP)
sudo dnf module reset php
sudo dnf module enable php:8.1
sudo dnf module install php

# 安装扩展
sudo dnf install php-fpm php-mysqlnd php-curl php-gd php-mbstring php-xml php-zip
```

## 配置 PHP-FPM

### Ubuntu/Debian (PHP 7.4+)

```bash
# 编辑 PHP-FPM 配置
sudo nano /etc/php/8.1/fpm/pool.d/www.conf

# 修改用户和组 (可选)
; user = www-data
; group = www-data

# 重启 PHP-FPM
sudo systemctl restart php8.1-fpm

# 查看状态
sudo systemctl status php8.1-fpm
```

### CentOS/Rocky/Alma

```bash
# 编辑 PHP-FPM 配置
sudo nano /etc/php-fpm.d/www.conf

# 修改用户和组
; user = apache
; group = apache
# 改为
user = nginx
group = nginx

# 启动并设置开机自启
sudo systemctl start php-fpm
sudo systemctl enable php-fpm

# 查看状态
sudo systemctl status php-fpm
```

## 常用 PHP 配置调整

```ini
# /etc/php/8.1/fpm/php.ini (或 /etc/php.ini)
; 上传文件大小限制
upload_max_filesize = 50M
post_max_size = 50M

; 内存限制
memory_limit = 256M

; 执行时间
max_execution_time = 300
max_input_time = 300

; 时区
date.timezone = Asia/Shanghai

; 显示错误 (生产环境关闭)
display_errors = Off
error_log = /var/log/php/error.log
```

## PHP 扩展安装

```bash
# Ubuntu/Debian
sudo apt-get install php-扩展名

# 常用扩展
sudo apt-get install php-mysql     # MySQL
sudo apt-get install php-pgsql     # PostgreSQL
sudo apt-get install php-redis     # Redis
sudo apt-get install php-imagick  # 图片处理
sudo apt-get install php-bcmath   # 高精度计算
sudo apt-get install php-soap     # SOAP
sudo apt-get install php-ldap     # LDAP

# CentOS/Rocky
sudo dnf install php-扩展名
```

## Composer 安装 (PHP 依赖管理)

```bash
# 下载安装脚本
curl -sS https://getcomposer.org/installer | php

# 移动到全局
sudo mv composer.phar /usr/local/bin/composer

# 验证
composer --version

# 加速 (国内镜像)
composer config -g repo.packagist composer https://packagist.phpcomposer.com
# 或使用腾讯镜像
composer config -g repo.packagist composer https://mirr.tencent.com/packagist/
```

## WordPress PHP 配置建议

```ini
; wp-config.php 中不需要在 php.ini 设置的推荐值
; 这些值可以在 wp-config.php 中直接设置
```

```php
// wp-config.php
@ini_set('max_execution_time', '300');
@ini_set('post_max_size', '50M');
@ini_set('upload_max_filesize', '50M');
@ini_set('memory_limit', '256M');
define('WP_MEMORY_LIMIT', '256M');
define('WP_MAX_MEMORY_LIMIT', '512M');
```

## 常见问题排查

```bash
# 检查 PHP-FPM 是否运行
ps aux | grep php-fpm

# 检查端口监听
netstat -tlnp | grep php
ss -tlnp | grep php

# 查看 PHP-FPM 日志
sudo tail -f /var/log/php-fpm/error.log

# 测试 PHP
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
# 访问 http://your-domain/info.php 查看
sudo rm /var/www/html/info.php  # 测试后删除
```
