# MongoDB 安装与配置指南

## 支持的操作系统

| 发行版 | 安装方式 |
|--------|----------|
| Ubuntu/Debian | APT 仓库 |
| CentOS/Rocky/AlmaLinux | YUM/DNF 仓库 |

## 安装 MongoDB

### Ubuntu 22.04 / 20.04

```bash
# 安装依赖
sudo apt-get install gnupg curl

# 添加 MongoDB GPG 密钥
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    --dearmor

# 添加 MongoDB APT 仓库
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# 安装 MongoDB
sudo apt-get update
sudo apt-get install -y mongodb-org

# 启动并设置开机自启
sudo systemctl start mongod
sudo systemctl enable mongod

# 检查状态
sudo systemctl status mongod
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# 创建 repo 文件
sudo nano /etc/yum.repos.d/mongodb-org-7.0.repo

# 写入以下内容 (CentOS 7 x86_64)
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc

# 安装
sudo yum install -y mongodb-org

# 启动并设置开机自启
sudo systemctl start mongod
sudo systemctl enable mongod
```

## 配置文件位置

| 路径 | 说明 |
|------|------|
| `/etc/mongod.conf` | 主配置文件 |
| `/var/log/mongodb/` | 日志目录 |
| `/var/lib/mongo/` | 数据目录 |
| `/var/lib/mongodb/` | 数据目录 (Ubuntu) |

## 基本配置

```yaml
# /etc/mongod.conf
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1  # 仅本地访问
  # bindIp: 0.0.0.0  # 允许远程访问 (需要配合防火墙)

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# 安全配置
security:
  authorization: enabled  # 启用用户认证后添加
```

## 用户管理

```javascript
// 连接 MongoDB
mongosh
// 或
mongo

// 创建管理员用户
use admin
db.createUser({
    user: "admin",
    pwd: "strong_password",
    roles: [
        { role: "root", db: "admin" }
    ]
})

// 创建应用数据库用户
use myapp
db.createUser({
    user: "myapp_user",
    pwd: "app_password",
    roles: [
        { role: "readWrite", db: "myapp" }
    ]
})

// 查看所有用户
db.adminCommand({ listUsers: 1 })

// 修改用户密码
db.changeUserPassword("username", "new_password")

// 删除用户
db.dropUser("username")
```

## 启用认证

```bash
# 编辑配置文件
sudo nano /etc/mongod.conf

# 在 security 部分添加/修改
security:
  authorization: enabled

# 重启服务
sudo systemctl restart mongod
```

## 远程访问配置

### 修改绑定地址

```yaml
# /etc/mongod.conf
net:
  port: 27017
  bindIp: 0.0.0.0  # 允许所有 IP 访问
```

### 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 27017/tcp

# CentOS/Rocky/Alma
sudo firewall-cmd --permanent --add-port=27017/tcp
sudo firewall-cmd --reload
```

## 数据库操作

```javascript
// 查看所有数据库
show dbs

// 切换/创建数据库
use myapp

// 查看当前数据库
db

// 创建集合
db.createCollection("users")

// 插入文档
db.users.insertOne({ name: "张三", email: "zhangsan@example.com", age: 25 })
db.users.insertMany([
    { name: "李四", email: "lisi@example.com", age: 30 },
    { name: "王五", email: "wangwu@example.com", age: 28 }
])

// 查询文档
db.users.find()                    // 查询所有
db.users.find({ name: "张三" })     // 条件查询
db.users.findOne({ name: "张三" })  // 查询单个

// 更新文档
db.users.updateOne(
    { name: "张三" },
    { $set: { age: 26 } }
)

// 删除文档
db.users.deleteOne({ name: "张三" })

// 查看集合
show collections

// 删除集合
db.users.drop()
```

## 备份与恢复

### 备份

```bash
# 备份所有数据库
mongodump --out=/var/backups/mongodb/backup_$(date +%Y%m%d)

# 备份指定数据库
mongodump --db=myapp --out=/var/backups/mongodb/backup_$(date +%Y%m%d)

# 压缩备份
mongodump --gzip --archive=/var/backups/mongodb/backup.gz
```

### 恢复

```bash
# 恢复所有数据库
mongorestore /var/backups/mongodb/backup_20240101

# 恢复指定数据库
mongorestore --db=myapp /var/backups/mongodb/backup_20240101/myapp

# 从压缩文件恢复
mongorestore --gzip --archive=/var/backups/mongodb/backup.gz
```

### 备份脚本

```bash
#!/bin/bash
# backup_mongodb.sh

BACKUP_DIR="/var/backups/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份所有数据库
mongodump --gzip --archive=$BACKUP_DIR/backup_$DATE.gz

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "MongoDB backup completed: $DATE"
```

## Docker 部署 MongoDB

```bash
# 拉取镜像
docker pull mongo:7.0

# 运行容器 (无认证)
docker run -d \
    --name mongodb \
    -p 27017:27017 \
    -v mongodb_data:/data/db \
    -v /var/backups:/backup \
    mongo:7.0

# 运行容器 (有认证)
docker run -d \
    --name mongodb \
    -p 27017:27017 \
    -e MONGO_INITDB_ROOT_USERNAME=admin \
    -e MONGO_INITDB_ROOT_PASSWORD=strong_password \
    -v mongodb_data:/data/db \
    mongo:7.0

# 使用 docker-compose
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: strong_password
      MONGO_INITDB_DATABASE: myapp
    volumes:
      - mongodb_data:/data/db
      - ./backup:/backup
    restart: unless-stopped

volumes:
  mongodb_data:
```

## 常见问题排查

```bash
# 检查服务状态
sudo systemctl status mongod

# 查看日志
sudo tail -f /var/log/mongodb/mongod.log

# 检查端口
netstat -tlnp | grep 27017
ss -tlnp | grep 27017

# 测试连接
mongosh
# 或
mongo

# 连接远程数据库
mongosh --host 192.168.1.100 --port 27017 -u admin -p --authenticationDatabase admin
```

## 性能优化建议

```yaml
# /etc/mongod.conf 性能相关配置
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1  # 根据可用内存调整 (一般为总内存的 50-60%)
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true
```

```javascript
// 查看当前连接数
db.serverStatus().connections

// 查看数据库大小
db.stats()

// 查看集合统计
db.collection.stats()

// 创建索引
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ name: 1, age: -1 })
```
