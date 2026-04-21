# MySQL/MariaDB 安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install mysql-server` |
| CentOS/Rocky/AlmaLinux | `yum install mariadb-server` (CentOS 7) 或 `dnf install mariadb-server` |

## 安装 MySQL/MariaDB

### Ubuntu/Debian

```bash
# 更新软件源
sudo apt-get update

# 安装 MySQL Server
sudo apt-get install mysql-server

# 安装完成后运行安全脚本
sudo mysql_secure_installation

# 启动并设置开机自启
sudo systemctl start mysql
sudo systemctl enable mysql

# 检查状态
sudo systemctl status mysql
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# CentOS 7 使用 MariaDB (MySQL 替代品，兼容)
sudo yum install mariadb-server mariadb

# 启动并设置开机自启
sudo systemctl start mariadb
sudo systemctl enable mariadb

# 运行安全脚本
sudo mysql_secure_installation
```

### Rocky Linux 9+ / AlmaLinux 9+ (安装 MySQL 8)

```bash
# 添加 MySQL Yum 仓库
sudo dnf install https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm

# 安装 MySQL Server
sudo dnf install mysql-community-server

# 启动并设置开机自启
sudo systemctl start mysqld
sudo systemctl enable mysqld

# 获取临时密码
sudo grep 'temporary password' /var/log/mysqld.log
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/mysql/mysql.conf.d/mysqld.cnf` | MySQL 主配置 (Ubuntu) |
| `/etc/my.cnf` | MySQL/MariaDB 主配置 (CentOS) |
| `/etc/my.cnf.d/` | 额外配置目录 (CentOS) |
| `/var/log/mysql/` | 日志目录 |
| `/var/lib/mysql/` | 数据目录 |

## 基本配置优化

```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf 或 /etc/my.cnf
[mysqld]
# 字符集
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 连接数
max_connections = 200

# 缓存大小 (根据服务器内存调整，一般为总内存的 50-70%)
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M

# 日志
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 二进制日志 (用于主从复制)
log-bin = mysql-bin
binlog_format = row
expire_logs_days = 7

# 临时表大小
tmp_table_size = 64M
max_heap_table_size = 64M
```

## 用户管理

```sql
-- 登录 MySQL
sudo mysql

-- 或 MySQL 8 (需要密码)
mysql -u root -p

-- 创建用户 (MySQL 8)
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
CREATE USER 'username'@'%' IDENTIFIED BY 'password';

-- 创建用户并授权 (MySQL 8)
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'localhost';
FLUSH PRIVILEGES;

-- 授权远程访问
GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'%';
FLUSH PRIVILEGES;

-- 修改用户密码
ALTER USER 'username'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;

-- 查看用户权限
SHOW GRANTS FOR 'username'@'localhost';

-- 删除用户
DROP USER 'username'@'localhost';
```

## 数据库操作

```sql
-- 创建数据库
CREATE DATABASE database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 查看所有数据库
SHOW DATABASES;

-- 选择数据库
USE database_name;

-- 导入数据
source /path/to/backup.sql

-- 或通过命令行导入
mysql -u username -p database_name < /path/to/backup.sql

-- 导出数据
mysqldump -u username -p database_name > backup.sql

-- 导出所有数据库
mysqldump -u username -p --all-databases > all_databases.sql
```

## 远程访问配置

### 允许远程连接

```sql
-- 创建远程用户
CREATE USER 'remote_user'@'%' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON database_name.* TO 'remote_user'@'%';
FLUSH PRIVILEGES;
```

### 修改绑定地址

```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf
bind-address = 0.0.0.0
# 或者注释掉 bind-address 来监听所有地址
```

### 开放防火墙端口

```bash
# Ubuntu/Debian (使用 UFW)
sudo ufw allow 3306/tcp

# CentOS/Rocky/AlmaLinux (使用 firewall-cmd)
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
```

## 备份与恢复

### 自动备份脚本

```bash
#!/bin/bash
# backup_mysql.sh

BACKUP_DIR="/var/backups/mysql"
MYSQL_USER="backup_user"
MYSQL_PASSWORD="backup_password"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份所有数据库
mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --all-databases > $BACKUP_DIR/all_databases_$DATE.sql

# 压缩备份文件
gzip $BACKUP_DIR/all_databases_$DATE.sql

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# 添加定时任务
sudo crontab -e

# 每天凌晨 2 点执行备份
0 2 * * * /bin/bash /opt/backup_mysql.sh >> /var/log/mysql_backup.log 2>&1
```

## 常见问题排查

```bash
# 检查 MySQL 服务状态
sudo systemctl status mysql
sudo systemctl status mariadb

# 查看错误日志
sudo tail -f /var/log/mysql/error.log
sudo tail -f /var/log/mysqld.log  # CentOS

# 检查端口
netstat -tlnp | grep 3306
ss -tlnp | grep 3306

# 重置 root 密码 (紧急情况)
sudo systemctl stop mysql
sudo mysqld_safe --skip-grant-tables &
mysql -u root
UPDATE mysql.user SET Password=PASSWORD('new_password') WHERE User='root';
FLUSH PRIVILEGES;
killall mysqld
sudo systemctl start mysql
```

## Docker 部署 MySQL

```bash
# 拉取镜像
docker pull mysql:8.0

# 运行容器
docker run -d \
    --name mysql \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD=strong_password \
    -e MYSQL_DATABASE=myapp \
    -e MYSQL_USER=appuser \
    -e MYSQL_PASSWORD=app_password \
    -v mysql_data:/var/lib/mysql \
    -v /var/backups:/backup \
    mysql:8.0

# 查看日志
docker logs mysql

# 连接数据库
docker exec -it mysql mysql -u root -p
```

## 性能优化建议

```sql
-- 查看慢查询
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time%';

-- 查看连接数
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Max_used_connections';

-- 查看缓存命中率
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- 分析查询 (需要 EXPLAIN)
EXPLAIN SELECT * FROM table_name WHERE condition;
```
