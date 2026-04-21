# Node.js 环境安装与配置指南

## 支持的操作系统

| 发行版 | 安装方式 |
|--------|----------|
| Ubuntu/Debian | 通过 NodeSource 或 nvm |
| CentOS/Rocky/AlmaLinux | 通过 NodeSource 或 nvm |

## 安装 Node.js

### 方法一：NodeSource (推荐)

```bash
# Ubuntu/Debian - 安装 Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# CentOS/Rocky/Alma - 安装 Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 验证
node --version
npm --version
```

### 方法二：nvm (多版本管理)

```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc  # 或 source ~/.zshrc

# 验证 nvm
nvm --version

# 安装 Node.js LTS 版本
nvm install --lts

# 或安装指定版本
nvm install 18
nvm install 20
nvm install --lts=iron

# 列出已安装的版本
nvm ls

# 使用特定版本
nvm use 18

# 设置默认版本
nvm alias default 18
```

## npm 配置

### 设置 npm 镜像 (国内加速)

```bash
# 设置淘宝镜像
npm config set registry https://registry.npmmirror.com

# 或设置腾讯镜像
npm config set registry https://mirr.tencent.com/npm/

# 验证设置
npm config get registry

# 查看所有配置
npm config list
```

### 设置 npm 缓存目录

```bash
# 设置缓存目录
npm config set cache ~/.npm

# 永久保存配置
npm config set save-prefix "~"
```

## 创建 Node.js 项目

```bash
# 创建项目目录
mkdir -p /var/www/myapp
cd /var/www/myapp

# 初始化项目
npm init -y

# 安装依赖
npm install express
npm install koa
npm install fastify

# 安装开发依赖
npm install --save-dev nodemon
npm install --save-dev typescript @types/node

# 安装全局工具
npm install -g pm2
npm install -g yarn
```

## PM2 进程管理器

PM2 是 Node.js 常用的进程管理器，支持负载均衡、自动重启、日志管理等。

### 安装 PM2

```bash
# 全局安装
npm install -g pm2

# 或在项目安装
npm install pm2
```

### 基本命令

```bash
# 启动应用
pm2 start app.js

# 启动并设置名称
pm2 start app.js --name "my-app"

# 启动多进程 (根据 CPU 核心数)
pm2 start app.js -i max

# 查看进程列表
pm2 list
pm2 status

# 查看详细信息
pm2 info my-app

# 查看日志
pm2 logs my-app
pm2 logs my-app --lines 100

# 重启应用
pm2 restart my-app

# 重载应用 (零停机)
pm2 reload my-app

# 停止应用
pm2 stop my-app

# 删除应用
pm2 delete my-app

# 监控 CPU/内存
pm2 monit
```

### PM2 配置文件

```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'my-api',
      script: './dist/index.js',
      cwd: '/var/www/myapp',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 8080
      },
      error_file: '/var/log/pm2/my-api-error.log',
      out_file: '/var/log/pm2/my-api-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      merge_logs: true,
      max_memory_restart: '500M',
      restart_time: 10,
      max_restarts: 10,
      autorestart: true
    }
  ]
};
```

```bash
# 使用配置文件启动
pm2 start ecosystem.config.js
pm2 start ecosystem.config.js --env production
```

### PM2 Startup (开机自启)

```bash
# 生成启动脚本
pm2 startup

# 保存当前进程列表
pm2 save

# 查看启动脚本
pm2 startup
```

## Systemd 服务配置

```ini
# /etc/systemd/system/node-app.service
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/myapp
Environment=NODE_ENV=production
Environment=PORT=8080
ExecStart=/usr/bin/node /var/www/myapp/server.js
Restart=always
RestartSec=5
StandardOut=syslog
StandardError=syslog
SyslogIdentifier=node-app

[Install]
WantedBy=multi-user.target
```

```bash
# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable node-app
sudo systemctl start node-app
sudo systemctl status node-app
```

## Nginx 反向代理配置

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

## 常见问题排查

```bash
# 检查 Node.js 版本
node --version

# 检查 npm 版本
npm --version

# 检查全局模块路径
npm root -g

# 查看已安装的全局模块
npm list -g --depth=0

# 清理 npm 缓存
npm cache clean --force

# 解决权限问题 (不要用 sudo npm)
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## yarn 安装 (可选)

```bash
# 通过 npm 安装
npm install -g yarn

# 或通过脚本安装
curl -o- -L https://yarnpkg.com/install.sh | bash

# 验证
yarn --version

# 设置镜像
yarn config set registry https://registry.npmmirror.com
```
