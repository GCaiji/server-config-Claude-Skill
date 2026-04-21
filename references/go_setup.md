# Go 环境安装与配置指南

## 支持的操作系统

| 发行版 | 安装方式 |
|--------|----------|
| Ubuntu/Debian | 官方压缩包 / apt |
| CentOS/Rocky/AlmaLinux | 官方压缩包 / yum |
| macOS | brew / 官方压缩包 |
| Windows | 官方安装包 / scoop |

## 安装 Go

### 方法一：官方安装脚本（推荐）

```bash
# Linux/macOS 一键安装
curl -fsSL https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -

# 或指定版本
wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
sudo rm go1.22.3.linux-amd64.tar.gz
```

### 方法二：apt 安装 (Ubuntu/Debian)

```bash
# 安装最新稳定版
sudo apt-get update
sudo apt-get install -y golang-go

# 或安装指定版本 (通过官方 PPA)
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install -y golang-1.21

# 验证
go version
```

### 方法三：dnf 安装 (CentOS/Rocky/Alma)

```bash
# 安装 EPEL 源后安装
sudo dnf install epel-release
sudo dnf install golang

# 验证
go version
```

### 方法四：使用版本管理器 gvm

```bash
# 安装 gvm
curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash

# 重新加载 shell
source ~/.bashrc

# 安装指定版本
gvm install go1.22.3
gvm use go1.22.3

# 设置为默认版本
gvm use go1.22.3 --default
```

## 配置环境变量

```bash
# 编辑 ~/.bashrc 或 ~/.zshrc
nano ~/.bashrc

# 添加以下内容
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
export GO111MODULE=on

# 使配置生效
source ~/.bashrc
```

### 验证配置

```bash
# 查看 Go 版本
go version

# 查看 Go 环境
go env

# 验证 GOPATH
go env GOPATH

# 测试编译
go version
```

## 设置 Go 模块代理（国内加速）

```bash
# 设置 GOPROXY
go env -w GOPROXY=https://goproxy.cn,direct

# 设置私有仓库
go env -w GOPRIVATE=*.internal.com

# 或使用七牛云代理
go env -w GOPROXY=https://goproxy.io,direct
```

## 编译 Go 项目

### 基本编译

```bash
# 进入项目目录
cd /path/to/project

# 下载依赖
go mod download

# 编译
go build -o output_binary main.go

# 编译所有平台
GOOS=linux GOARCH=amd64 go build -o app-linux main.go
GOOS=windows GOARCH=amd64 go build -o app.exe main.go
GOOS=darwin GOARCH=amd64 go build -o app-macos main.go
```

### 编译常见问题

#### 问题 1：多 main 文件冲突

```bash
# 错误：项目中多个文件有 main 函数
# download_assets.go:15:6: main redeclared in this block
# copy_lfs.go:10:6: main redeclared in this block

# 解决方案：只编译主入口文件
go build -o yw_back main.go

# 或排除其他 main 文件
go build -o yw_back main.go download_assets.go copy_lfs.go
```

#### 问题 2：Go 版本不匹配

```bash
# 错误：module requires Go 1.21

# 解决方案 1：升级 Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
go version

# 解决方案 2：使用 docker 编译
docker run --rm -v $(pwd):/app -w /app golang:1.22 go build -o output main.go

# 解决方案 3：使用 CI/CD 服务编译
```

#### 问题 3：依赖下载失败

```bash
# 设置代理
go env -w GOPROXY=https://goproxy.cn,direct

# 或使用阿里云镜像
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct

# 清理缓存
go clean -modcache

# 重新下载
go mod download
```

## 使用 Go 交叉编译

### 安装交叉编译工具

```bash
# 安装 gox（推荐）
go install github.com/gox/gox@latest
gox --version

# 安装 g交叉编译工具
go install github.com/Evertras/go-cross@latest
```

### 编译多平台版本

```bash
# 使用 gox 编译
gox -osarch="linux/amd64 linux/arm64 windows/amd64 darwin/amd64" -output="dist/{{.OS}}-{{.Arch}}/app"

# 使用 goreleaser（专业发布工具）
# .goreleaser.yml 配置
```

## Go 项目结构

### 标准项目结构

```
project/
├── cmd/
│   └── main.go           # 主入口
├── internal/             # 内部包
│   └── api/
├── pkg/                  # 公共包
├── configs/              # 配置文件
├── go.mod                # 依赖管理
├── go.sum                # 依赖校验
└── Makefile              # 构建脚本
```

### Go Module 配置

```bash
# 初始化模块
go mod init github.com/yourusername/project

# 添加依赖
go get github.com/gin-gonic/gin@v1.9.1

# 更新依赖
go get -u github.com/gin-gonic/gin

# 整理依赖
go mod tidy

# 验证依赖
go mod verify
```

## Systemd 服务配置

```ini
# /etc/systemd/system/go-app.service
[Unit]
Description=Go Application
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/goapp
Environment="PORT=8080"
Environment="MODE=production"
ExecStart=/var/www/goapp/go-app
Restart=always
RestartSec=5
StandardOut=syslog
StandardError=syslog
SyslogIdentifier=go-app

[Install]
WantedBy=multi-user.target
```

```bash
# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable go-app
sudo systemctl start go-app
sudo systemctl status go-app
```

## PM2 部署 Go 应用

```bash
# 直接启动
pm2 start /path/to/app --name "my-app"

# 带环境变量
PORT=8080 MODE=production pm2 start /path/to/app --name "my-app"

# 查看日志
pm2 logs my-app

# 重启
pm2 restart my-app
```

## Docker 部署 Go 应用

### 多阶段构建

```dockerfile
# 构建阶段
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 运行阶段
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

```bash
# 构建镜像
docker build -t my-go-app:latest .

# 运行容器
docker run -d -p 8080:8080 --name my-go-app my-go-app:latest

# 使用 docker-compose
```

### docker-compose.yml

```yaml
version: '3.8'
services:
  app:
    build: .
    container_name: my-go-app
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - MODE=production
      - DB_HOST=db
      - DB_PORT=3306
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: myapp
```

## 常用 Go 框架

| 框架 | 说明 | 特点 |
|------|------|------|
| Gin | HTTP Web 框架 | 高性能，轻量级 |
| Echo | HTTP Web 框架 | 高性能，功能丰富 |
| Fiber | HTTP Web 框架 | 类 Express 风格 |
| Chi | HTTP Web 框架 | 轻量，路由灵活 |
| Beego | 全栈框架 | MVC，内置工具 |
| Revel | 全栈框架 | 全功能，开箱即用 |

## 常用命令速查

```bash
# 版本和环境
go version                    # 查看版本
go env                        # 查看环境变量
go env GOPATH                # 查看 GOPATH

# 依赖管理
go mod init [module]         # 初始化模块
go mod download              # 下载依赖
go mod tidy                   # 整理依赖
go get [package]             # 添加依赖
go mod vendor                # 复制依赖到 vendor

# 编译和运行
go build [packages]          # 编译
go run [file]                # 运行
go test [packages]           # 测试
go install [packages]        # 安装为命令

# 代码质量
go fmt ./...                 # 格式化代码
go vet ./...                 # 检查代码
go lint                      # 代码检查
golangci-lint run           # 综合检查
```

## 版本要求说明

| 项目要求 | 服务器版本 | 解决方案 |
|----------|-----------|----------|
| Go 1.21 | Go 1.19 | 升级 Go / 使用预编译 / Docker 编译 |
| Go 1.22 | Go 1.21 | 升级 Go / 使用预编译 / Docker 编译 |
| Go 1.23 | Go 1.22 | 升级 Go / 使用预编译 / Docker 编译 |
| Go latest | - | 使用官方最新版本 |

## 故障排查

### 1. 编译时找不到依赖

```bash
# 清理缓存
go clean -modcache

# 重新下载
go mod download
go mod tidy
```

### 2. CGO 交叉编译问题

```bash
# 禁用 CGO
CGO_ENABLED=0 go build main.go

# 或使用 alpine 镜像（无 CGO）
FROM golang:1.22-alpine
```

### 3. 模块版本冲突

```bash
# 查看依赖树
go mod graph

# 使用 replace 解决冲突
go mod edit -replace=old/module=@v1.0.0=new/module=@v1.1.0
```
