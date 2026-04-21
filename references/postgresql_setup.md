# PostgreSQL 安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install postgresql` |
| CentOS/Rocky/AlmaLinux | `yum install postgresql-server` |

## 安装 PostgreSQL

### Ubuntu 22.04+

```bash
# 安装 PostgreSQL
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# 启动并设置开机自启
sudo systemctl start postgresql
sudo systemctl enable postgresql

# 检查状态
sudo systemctl status postgresql
```

### Ubuntu 20.04 / 18.04 (安装新版 PostgreSQL)

```bash
# 添加 PostgreSQL APT 仓库
sudo apt-get install curl ca-certificates gnupg

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-key.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql-key.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# 安装 PostgreSQL 15
sudo apt-get update
sudo apt-get install postgresql-15

# 启动服务
sudo systemctl start postgresql-15
sudo systemctl enable postgresql-15
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# CentOS 7 安装 PostgreSQL 13
sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redis-repo-latest.noarch.rpm
sudo yum install postgresql13 postgresql13-server

# 初始化数据库
sudo /usr/pgsql-13/bin/postgresql-13-setup initdb

# 启动并设置开机自启
sudo systemctl start postgresql-13
sudo systemctl enable postgresql-13
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/postgresql/15/main/postgresql.conf` | 主配置 (Ubuntu) |
| `/var/lib/pgsql/data/postgresql.conf` | 主配置 (CentOS) |
| `/etc/postgresql/15/main/pg_hba.conf` | 认证配置 (Ubuntu) |
| `/var/lib/pgsql/data/pg_hba.conf` | 认证配置 (CentOS) |
| `/var/log/postgresql/` | 日志目录 |

## 基本配置

```ini
# /etc/postgresql/15/main/postgresql.conf (或 /var/lib/pgsql/data/postgresql.conf)

# 监听地址
listen_addresses = '*'

# 端口
port = 5432

# 字符集
datestyle = 'iso, mdy'
timezone = 'Asia/Shanghai'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search = 'pg_catalog.english'

# 连接配置
max_connections = 200

# 内存配置 (根据服务器内存调整)
shared_buffers = 256MB              # 约为总内存的 25%
effective_cache_size = 768MB        # 约为总内存的 75%
work_mem = 16MB
maintenance_work_mem = 128MB

# 写入性能
checkpoint_completion_target = 0.9
wal_buffers = 16MB
max_wal_size = 1GB
min_wal_size = 80MB

# 日志
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'ddl'
log_duration = off
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h'

# 慢查询日志
log_min_duration_statement = 1000  # 记录超过 1 秒的查询
```

## 用户管理

```bash
# 切换到 postgres 用户
sudo -u postgres -i

# 登录 psql
psql

# 在系统命令行执行
sudo -u postgres psql
```

```sql
-- 创建用户
CREATE USER username WITH PASSWORD 'password';

-- 创建数据库并指定所有者
CREATE DATABASE myapp OWNER username;

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE myapp TO username;

-- 修改用户密码
ALTER USER username WITH PASSWORD 'new_password';

-- 设置用户为超级用户
ALTER USER username WITH SUPERUSER;

-- 删除用户
DROP USER username;
```

## 远程访问配置

### 修改 pg_hba.conf

```bash
# Ubuntu
sudo nano /etc/postgresql/15/main/pg_hba.conf

# CentOS
sudo nano /var/lib/pgsql/data/pg_hba.conf
```

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# 允许本地连接
local   all             all                                     peer

# 允许 IPv4 本地连接
host    all             all             127.0.0.1/32            scram-sha-256

# 允许指定 IP 段访问 (按需修改)
host    all             all             192.168.1.0/24          scram-sha-256

# 允许所有 IP 访问 (测试用，生产环境不推荐)
host    all             all             0.0.0.0/0              scram-sha-256
```

### 修改 postgresql.conf

```ini
# /etc/postgresql/15/main/postgresql.conf
listen_addresses = '*'
```

### 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 5432/tcp

# CentOS
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload
```

## 数据库操作

```sql
-- 连接数据库
psql -U username -d myapp -h localhost -p 5432

-- 创建数据库
CREATE DATABASE myapp;

-- 列出所有数据库
\l

-- 列出所有表
\dt

-- 列出所有用户
\du

-- 切换数据库
\c myapp

-- 查看表结构
\d table_name

-- 备份数据库
pg_dump -U username -d myapp > backup.sql

-- 导入数据库
psql -U username -d myapp < backup.sql

-- 备份所有数据库
pg_dumpall -U postgres > all_databases.sql

-- 导入所有数据库
psql -U postgres < all_databases.sql
```

## 备份脚本

```bash
#!/bin/bash
# backup_postgres.sh

BACKUP_DIR="/var/backups/postgresql"
PG_USER="postgres"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份指定数据库
pg_dump -U $PG_USER myapp > $BACKUP_DIR/myapp_$DATE.sql

# 备份所有数据库
pg_dumpall -U $PG_USER > $BACKUP_DIR/all_databases_$DATE.sql

# 压缩
gzip $BACKUP_DIR/myapp_$DATE.sql
gzip $BACKUP_DIR/all_databases_$DATE.sql

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "PostgreSQL backup completed: $DATE"
```

```bash
# 添加定时任务
sudo crontab -e

# 每天凌晨 3 点执行备份
0 3 * * * /bin/bash /opt/backup_postgres.sh >> /var/log/postgres_backup.log 2>&1
```

## 常见问题排查

```bash
# 检查服务状态
sudo systemctl status postgresql

# 查看日志
sudo tail -f /var/log/postgresql/postgresql-15-main.log
sudo tail -f /var/lib/pgsql/log/*.log  # CentOS

# 检查端口
netstat -tlnp | grep 5432
ss -tlnp | grep 5432

# 测试连接
psql -U postgres -h localhost

# 重启服务
sudo systemctl restart postgresql
```

## Docker 部署 PostgreSQL

```bash
# 拉取镜像
docker pull postgres:15

# 运行容器
docker run -d \
    --name postgres \
    -p 5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=strong_password \
    -e POSTGRES_DB=myapp \
    -v postgres_data:/var/lib/postgresql/data \
    -v /var/backups:/backup \
    postgres:15

# 查看日志
docker logs postgres

# 连接数据库
docker exec -it postgres psql -U postgres
```

## 性能优化建议

```sql
-- 查看当前配置
SHOW all;

-- 查看连接数
SELECT count(*) FROM pg_stat_activity;

-- 查看数据库大小
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database;

-- 查看慢查询
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- 分析查询
EXPLAIN ANALYZE SELECT * FROM table_name WHERE condition;
```
