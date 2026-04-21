# Redis 安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install redis-server` |
| CentOS/Rocky/AlmaLinux | `yum install redis` |

## 安装 Redis

### Ubuntu/Debian

```bash
# 更新软件源
sudo apt-get update

# 安装 Redis
sudo apt-get install redis-server

# 启动并设置开机自启
sudo systemctl start redis-server
sudo systemctl enable redis-server

# 检查状态
sudo systemctl status redis-server
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# 安装 Redis
sudo yum install redis

# 启动并设置开机自启
sudo systemctl start redis
sudo systemctl enable redis

# 检查状态
sudo systemctl status redis
```

### 编译安装 (获取最新版本)

```bash
# 安装编译依赖
sudo apt-get install build-essential tcl

# 下载 Redis 源码
cd /tmp
curl -fsSL https://github.com/redis/redis/archive/7.2.4.tar.gz -o redis.tar.gz
tar xzf redis.tar.gz
cd redis-7.2.4

# 编译安装
make
make test
sudo make install

# 创建配置目录
sudo mkdir /etc/redis
sudo cp redis.conf /etc/redis/redis.conf

# 创建用户和数据目录
sudo useradd -r -s /bin/false redis
sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chown redis:redis /etc/redis/redis.conf
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/redis/redis.conf` | 主配置文件 |
| `/etc/redis-sentinel/` | Sentinel 配置目录 |
| `/var/log/redis/` | 日志目录 (编译安装) |
| `/var/lib/redis/` | 数据目录 |
| `/var/log/redis/` | 日志目录 (APT 安装) |

## 基本配置

```ini
# /etc/redis/redis.conf

# 网络配置
bind 127.0.0.1 ::1          # 仅本地访问
# bind 0.0.0.0              # 允许远程访问 (配合防火墙)

port 6379
protected-mode yes           # 保护模式 (开启时需要密码)

# 密码认证
requirepass your_redis_password

# 持久化配置
save 900 1      # 900秒内有1次更改则保存
save 300 10      # 300秒内有10次更改则保存
save 60 10000    # 60秒内有10000次更改则保存

# 持久化方式
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec           # 每秒同步

# 内存配置
maxmemory 256mb              # 最大内存 (根据服务器调整)
maxmemory-policy allkeys-lru # 内存满时删除最近最少使用的 key

# 日志
loglevel notice
logfile /var/log/redis/redis-server.log

# 数据目录
dir /var/lib/redis
```

## 密码配置

```bash
# 方法一：编辑配置文件
sudo nano /etc/redis/redis.conf
# 添加或修改
requirepass your_strong_password

# 方法二：通过命令行设置 (临时)
redis-cli config set requirepass "new_password"
redis-cli config set requirepass ""

# 重启服务使配置生效
sudo systemctl restart redis-server
```

## 远程访问配置

### 修改绑定地址

```ini
# /etc/redis/redis.conf
bind 0.0.0.0 ::1

# 或者注释掉 bind 来监听所有地址
# bind 127.0.0.1 ::1
```

### 关闭保护模式

```ini
# /etc/redis/redis.conf
protected-mode no
```

### 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 6379/tcp

# CentOS/Rocky/Alma
sudo firewall-cmd --permanent --add-port=6379/tcp
sudo firewall-cmd --reload
```

## 基本操作

```bash
# 连接本地 Redis
redis-cli

# 连接远程 Redis
redis-cli -h 192.168.1.100 -p 6379

# 连接并认证
redis-cli -a your_password

# 认证 (连接后)
AUTH your_password

# Ping 测试
PING

# 设置 key
SET mykey "Hello World"
SET user:1 '{"name":"张三","age":25}'

# 获取 key
GET mykey
GET user:1

# 设置带过期时间的 key
SETEX session:abc123 3600 '{"user_id":1}'

# 检查 key 是否存在
EXISTS mykey

# 删除 key
DEL mykey

# 设置 key 的过期时间
EXPIRE mykey 60        # 60秒后过期
TTL mykey              # 查看剩余时间
PERSIST mykey          # 移除过期时间

# 列出所有 key
KEYS *
KEYS user:*

# 常用数据结构命令
LPUSH mylist "item1"           # 列表：左边添加
RPUSH mylist "item2"           # 列表：右边添加
LRANGE mylist 0 -1             # 列表：获取所有
HSET myhash name "张三"         # 哈希：设置字段
HGET myhash name               # 哈希：获取字段
HGETALL myhash                 # 哈希：获取所有
SADD myset "a" "b" "c"        # 集合：添加成员
SMEMBERS myset                 # 集合：获取所有成员
ZADD mysortedset 100 "item1"   # 有序集合：添加成员
ZRANGE mysortedset 0 -1       # 有序集合：获取成员
```

## 备份与恢复

### RDB 快照备份

```bash
# 手动触发快照
redis-cli BGSAVE

# 检查保存状态
redis-cli LASTSAVE

# 备份文件位置 (配置文件中指定)
ls /var/lib/redis/

# 复制备份
cp /var/lib/redis/dump.rdb /var/backups/dump_$(date +%Y%m%d).rdb
```

### AOF 持久化恢复

```bash
# Redis 自动使用 AOF 恢复
# 如果数据损坏，尝试修复
redis-cli -a your_password CONFIG GET appendonly
# 如果是 no，需要开启
redis-cli -a your_password CONFIG SET appendonly yes
```

### 备份脚本

```bash
#!/bin/bash
# backup_redis.sh

BACKUP_DIR="/var/backups/redis"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 触发快照备份
redis-cli -a your_password BGSAVE
sleep 5

# 复制 RDB 文件
cp /var/lib/redis/dump.rdb $BACKUP_DIR/dump_$DATE.rdb

# 如果启用了 AOF，复制 AOF 文件
if [ -f /var/lib/redis/appendonly.aof ]; then
    cp /var/lib/redis/appendonly.aof $BACKUP_DIR/appendonly_$DATE.aof
fi

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.rdb" -mtime +7 -delete
find $BACKUP_DIR -name "*.aof" -mtime +7 -delete

echo "Redis backup completed: $DATE"
```

## Docker 部署 Redis

```bash
# 运行 Redis 容器 (无认证)
docker run -d \
    --name redis \
    -p 6379:6379 \
    -v redis_data:/data \
    redis:latest \
    redis-server --appendonly yes

# 运行 Redis 容器 (有认证)
docker run -d \
    --name redis \
    -p 6379:6379 \
    -v redis_data:/data \
    redis:latest \
    redis-server --requirepass strong_password --appendonly yes

# 使用 docker-compose
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    command: redis-server --requirepass strong_password --appendonly yes
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

## 常用客户端库

```bash
# Python
pip install redis

# Node.js
npm install ioredis

# PHP
pecl install redis
```

## 常见问题排查

```bash
# 检查服务状态
sudo systemctl status redis
sudo systemctl status redis-server

# 查看日志
sudo tail -f /var/log/redis/redis-server.log

# 检查端口
netstat -tlnp | grep 6379
ss -tlnp | grep 6379

# 测试连接
redis-cli ping
redis-cli -a your_password ping

# 监控实时操作
redis-cli MONITOR

# 查看客户端连接
redis-cli CLIENT LIST

# 查看内存使用
redis-cli INFO memory

# 查看统计信息
redis-cli INFO stats
```

## 性能优化建议

```ini
# /etc/redis/redis.conf

# 内存配置 (关键)
maxmemory 512mb
maxmemory-policy allkeys-lru

# 持久化优化
appendonly yes
appendfsync everysec

# 网络优化
tcp-backlog 511
timeout 300
tcp-keepalive 300

# 慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128
```

```bash
# 查看慢查询
redis-cli SLOWLOG GET 10

# 查看 Redis 信息摘要
redis-cli INFO | grep -E "keyspace|hits|misses|connected"
```

## 主从复制配置

```ini
# 从节点配置 /etc/redis/redis.conf
replicaof 192.168.1.100 6379
masterauth your_password
```
