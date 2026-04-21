# 项目部署配置指南

## 概述

每个需要部署的项目都应该有一份 `PROJECT_DEPLOY.md` 配置文件，位于项目根目录。本技能在部署前会检查此文件，根据配置进行自动化部署，杜绝盲目探索导致的效率问题。

## 为什么需要项目部署配置？

- **快速部署**：避免每次部署都重新探索项目结构
- **配置复用**：数据库连接、环境变量等配置一次记录，反复使用
- **团队协作**：团队成员都可以使用相同配置进行部署
- **版本控制**：配置随项目一起管理，记录部署变更历史

## 配置检查流程

```
部署请求 → 检查 PROJECT_DEPLOY.md → 存在 → 执行部署
                                    ↓
                               不存在 → 创建配置 → 执行部署
```

---

## PROJECT_DEPLOY.md 配置模板

```markdown
# 项目部署配置

> 此文件由 Claude Code server-config 技能自动管理
> 部署前请确保配置正确

## 项目基本信息

| 字段 | 值 | 说明 |
|------|-----|------|
| 项目名称 | monopoly-backend | 后端服务 |
| 仓库地址 | https://git.qxht.cc/develop/yw_back | Git 仓库 |
| 分支 | main | 部署分支 |
| 负责人 | - | 可填写 |

## 技术栈

| 组件 | 版本 | 备注 |
|------|------|------|
| Go | 1.21+ | 必须使用 Go 1.21 以上版本 |
| Gin | - | Web 框架 |
| MySQL | 8.0 | Docker 容器 |
| Redis | - | Docker 容器 |
| Docker | 20.10+ | 容器化部署 |

## 目录结构

```
yw_back/
├── main.go              # 主入口（唯一 main 文件）
├── go.mod              # 依赖管理
├── go.sum              # 依赖校验
├── config/             # 配置目录
│   └── *.go           # 配置文件
├── controllers/        # 控制器
├── models/             # 数据模型
├── routes/             # 路由
├── middleware/         # 中间件
├── services/          # 业务逻辑
├── download_assets.go # 辅助脚本（独立运行）
├── copy_lfs.go        # 辅助脚本（独立运行）
└── yw_back            # 编译后的二进制文件
```

## 编译配置

### 编译命令

```bash
# 方法一：直接编译主入口
go build -o yw_back main.go

# 方法二：使用已有二进制文件
# 直接使用 /opt/kh/yw_back/yw_back（已预编译）
```

### Go 版本要求

- **最低版本**：Go 1.21
- **当前服务器**：Go 1.19（不支持编译，需要使用预编译二进制）
- **解决方案**：使用项目已有的 `yw_back` 二进制文件

### 编译注意事项

- `download_assets.go` 和 `copy_lfs.go` 有独立的 main 函数，不能与其他文件一起编译
- 建议使用预编译的二进制文件部署

## 环境变量配置

### 必需环境变量

| 变量名 | 示例值 | 说明 |
|--------|--------|------|
| PORT | 8082 | 服务监听端口 |
| JWT_SECRET | your-secret-key | JWT 密钥 |
| GITLFS_BASE_URL | https://git.qxht.cc/develop/yw_back/media/branch/main | Git LFS 地址 |
| LOCALE | zh-CN | 语言设置 |
| MODE | release | 运行模式 |

### MySQL 配置

| 变量名 | 示例值 | 说明 |
|--------|--------|------|
| MYSQL_HOST | 192.168.192.3 | MySQL 容器 IP |
| MYSQL_PORT | 3306 | MySQL 端口 |
| MYSQL_USER | root | 用户名 |
| MYSQL_PASSWORD | 114514 | 密码（Docker 环境变量） |
| MYSQL_DATABASE | monopoly | 数据库名 |

### Redis 配置

| 变量名 | 示例值 | 说明 |
|--------|--------|------|
| REDIS_HOST | 192.168.192.2 | Redis 容器 IP |
| REDIS_PORT | 6379 | Redis 端口 |
| REDIS_PASSWORD | - | 密码（无密码） |
| REDIS_DB | 0 | 数据库编号 |

## Docker 依赖服务

### 已有容器

| 容器名 | 镜像 | 端口映射 | 网络 |
|--------|------|----------|------|
| toilet-mysql | mysql:8.0 | 3306:3306 | bridge |
| toilet-redis | redis:latest | 6379:6379 | bridge |

### 连接信息

```bash
# 获取容器 IP
docker inspect toilet-mysql -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect toilet-redis -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# 获取 MySQL 密码
docker inspect toilet-mysql --format '{{json .Config.Env}}' | grep MYSQL_ROOT_PASSWORD
```

### 网络配置

- **问题**：Docker 容器使用默认 bridge 网络，主机无法通过容器名解析
- **解决方案**：使用容器 IP 或创建自定义网络

```bash
# 创建自定义网络（推荐）
docker network create app-network
docker network connect app-network toilet-mysql
docker network connect app-network toilet-redis
```

## 端口配置

### 已占用端口

| 端口 | 服务 | 说明 |
|------|------|------|
| 8080 | toilet-back | 已占用 |
| 8081 | - | 尝试中 |
| 8082 | yw_back | 当前使用 |

### 端口选择策略

1. 检查当前占用的端口：`ss -tlnp | grep :PORT`
2. 选择未被占用的端口
3. 确保防火墙开放该端口

## 健康检查

### 接口

```
GET /health
```

### 预期响应

```json
{
  "status": "ok"
}
```

### 验证命令

```bash
curl -s http://localhost:8082/health
```

## 部署命令

### 一键部署脚本

```bash
#!/bin/bash
# deploy.sh - 项目部署脚本

set -e

# 配置
PROJECT_NAME="monopoly-backend"
BINARY_NAME="yw_back"
PORT=8082
PROJECT_DIR="/opt/kh/yw_back"
MYSQL_HOST="192.168.192.3"
MYSQL_PASSWORD="114514"
MYSQL_DATABASE="monopoly"
REDIS_HOST="192.168.192.2"
JWT_SECRET="your-secret-key"

# 停止旧服务
pkill -f $BINARY_NAME || true

# 启动新服务
cd $PROJECT_DIR
MYSQL_HOST=$MYSQL_HOST \
MYSQL_USER=root \
MYSQL_PASSWORD=$MYSQL_PASSWORD \
MYSQL_DATABASE=$MYSQL_DATABASE \
REDIS_HOST=$REDIS_HOST \
PORT=$PORT \
JWT_SECRET=$JWT_SECRET \
GITLFS_BASE_URL="https://git.qxht.cc/develop/yw_back/media/branch/main" \
LOCALE="zh-CN" \
MODE="release" \
./$BINARY_NAME &

# 等待启动
sleep 3

# 健康检查
if curl -sf http://localhost:$PORT/health; then
    echo "Deployment successful!"
else
    echo "Health check failed!"
    exit 1
fi
```

### 使用 PM2 管理

```bash
# 创建 ecosystem 配置
pm2 start ecosystem.config.js --env production

# 查看状态
pm2 list
pm2 logs yw_back
```

## 故障排查

### Redis 连接失败

**症状**：`Failed to connect to Redis: dial tcp: lookup toilet-redis`

**原因**：Docker 容器名无法解析

**解决**：
```bash
# 方法1：使用容器 IP
REDIS_HOST=$(docker inspect toilet-redis -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

# 方法2：创建自定义网络
docker network create app-network
docker network connect app-network toilet-redis
```

### MySQL 连接失败

**症状**：`Access denied for user 'root' (using password: NO)`

**原因**：缺少密码配置

**解决**：
```bash
# 设置正确的环境变量
MYSQL_PASSWORD=114514
```

### 端口被占用

**症状**：`bind: address already in use`

**解决**：
```bash
# 查找占用端口的进程
ss -tlnp | grep :8082

# 杀死进程或使用新端口
```

### Go 版本不匹配

**症状**：`module requires Go 1.21`

**解决**：
```bash
# 方案1：使用预编译二进制
ls -la /opt/kh/yw_back/yw_back

# 方案2：升级 Go 版本
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version
```

## 部署检查清单

- [ ] 项目部署配置文档存在
- [ ] 二进制文件或编译环境就绪
- [ ] Docker 依赖服务运行正常
- [ ] 端口未被占用
- [ ] 环境变量配置正确
- [ ] 健康检查通过
- [ ] 日志输出正常

## 更新日志

| 日期 | 更新内容 | 更新人 |
|------|----------|--------|
| 2026-04-21 | 初始配置 | Claude |
```
