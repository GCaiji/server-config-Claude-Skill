# Docker 安装与配置指南

## 支持的操作系统

| 发行版 | 安装方式 |
|--------|----------|
| Ubuntu/Debian | Docker 官方脚本 |
| CentOS/Rocky/AlmaLinux | Docker 官方脚本 |

## 安装 Docker

### Ubuntu/Debian

```bash
# 安装依赖
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

# 添加 Docker GPG 密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker APT 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list

# 安装 Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker

# 检查状态
sudo systemctl status docker

# 查看版本
docker --version
docker compose version
```

### CentOS 7 / Rocky Linux 8+ / AlmaLinux

```bash
# 安装依赖
sudo yum install -y yum-utils

# 添加 Docker YUM 仓库
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker

# 检查状态
sudo systemctl status docker

# 查看版本
docker --version
docker compose version
```

### 使用官方安装脚本 (一键安装)

```bash
# 自动检测系统并安装
curl -fsSL https://get.docker.com | sudo sh

# 或使用阿里云镜像
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh --mirror Aliyun

# 启动并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker
```

## 配置 Docker

### 配置 Docker 镜像加速

```bash
# 创建配置目录
sudo mkdir -p /etc/docker

# 创建配置文件
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# 重启 Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 验证配置
docker info | grep -A 10 "Registry Mirrors"
```

### 配置日志轮转

```json
// /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

### 允许非 root 用户使用 Docker

```bash
# 创建 docker 用户组
sudo groupadd docker

# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 应用更改 (重新登录后生效)
newgrp docker

# 或使用当前会话
exec su -l $USER
```

## Docker Compose 使用

### 基本命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重新构建并启动
docker compose up -d --build

# 查看日志
docker compose logs -f

# 查看运行中的容器
docker compose ps

# 进入容器
docker compose exec app bash

# 停止并删除容器和网络
docker compose down -v

# 重新创建
docker compose up -d --force-recreate
```

### Docker Compose 示例 (WordPress)

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress_password
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - app_network

  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress_password
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - app_network

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    depends_on:
      - wordpress
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - wordpress_data:/var/www/html:ro
      - ./ssl:/etc/nginx/ssl:ro
    networks:
      - app_network

volumes:
  db_data:
  wordpress_data:

networks:
  app_network:
    driver: bridge
```

### Docker Compose 示例 (Node.js + MySQL)

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DB_HOST: db
      DB_PORT: 3306
      DB_USER: appuser
      DB_PASSWORD: app_password
      DB_NAME: myapp
    depends_on:
      - db
    networks:
      - app_network

  db:
    image: mysql:8.0
    container_name: db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: myapp
      MYSQL_USER: appuser
      MYSQL_PASSWORD: app_password
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - app_network

  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api
    networks:
      - app_network

volumes:
  db_data:

networks:
  app_network:
    driver: bridge
```

## Dockerfile 示例

### Node.js 应用

```dockerfile
# 使用官方 Node.js 镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production

# 启动命令
CMD ["node", "server.js"]
```

### 构建并运行

```bash
# 构建镜像
docker build -t myapp:latest .

# 运行容器
docker run -d \
    --name myapp \
    -p 3000:3000 \
    -e NODE_ENV=production \
    myapp:latest

# 查看日志
docker logs -f myapp

# 进入容器
docker exec -it myapp sh

# 停止并删除
docker stop myapp
docker rm myapp
```

## 常用 Docker 命令

```bash
# 镜像操作
docker images                          # 列出本地镜像
docker pull nginx:latest              # 拉取镜像
docker rmi nginx:latest              # 删除镜像
docker image prune                   # 清理未使用的镜像

# 容器操作
docker ps                            # 列出运行中的容器
docker ps -a                         # 列出所有容器
docker run -d nginx                  # 运行容器
docker stop container_id             # 停止容器
docker start container_id           # 启动容器
docker restart container_id          # 重启容器
docker rm container_id              # 删除容器
docker logs -f container_id         # 查看日志
docker exec -it container_id bash   # 进入容器

# 系统操作
docker system df                    # 查看磁盘使用
docker stats                        # 查看资源使用
docker network ls                   # 列出网络
docker volume ls                   # 列出卷
```

## 常见问题排查

```bash
# 检查 Docker 服务状态
sudo systemctl status docker

# 查看 Docker 日志
sudo journalctl -u docker -f

# 重启 Docker
sudo systemctl restart docker

# 测试 Docker 是否正常
sudo docker run hello-world

# 查看容器详细信息
docker inspect container_id

# 查看容器资源使用
docker stats container_id

# 修复网络问题
docker network prune
```

## 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 2375/tcp  # Docker API (如需远程管理)
sudo ufw allow 2376/tcp  # Docker API TLS

# CentOS/Rocky/Alma
sudo firewall-cmd --permanent --add-port=2375/tcp
sudo firewall-cmd --permanent --add-port=2376/tcp
sudo firewall-cmd --reload
```

## 数据管理

```bash
# 创建数据卷
docker volume create mydata

# 列出数据卷
docker volume ls

# 查看数据卷详情
docker volume inspect mydata

# 删除未使用的数据卷
docker volume prune

# 备份数据卷
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar cvf /backup/backup.tar /data

# 恢复数据卷
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar xvf /backup/backup.tar -C /
```
