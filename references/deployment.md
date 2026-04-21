# 自动化部署指南

## 部署流程概览

```
代码提交 → Git 仓库 → CI/CD 触发 → 构建 → 测试 → 部署 → 通知
```

## Git Hooks 自动部署

### 方式一：Gitolite 或 Gitea Webhook

```bash
# 在服务器上创建部署用户
sudo adduser deploy
sudo su - deploy

# 创建 Git 仓库
mkdir -p ~/git/deploy.git
cd ~/git/deploy.git
git init --bare

# 创建 post-receive hook
nano ~/git/deploy.git/hooks/post-receive
```

```bash
#!/bin/bash
# ~/git/deploy.git/hooks/post-receive

GIT_WORK_TREE=/var/www/myapp git checkout -f main

# 重新加载应用
cd /var/www/myapp
npm install --production
pm2 restart myapp || pm2 start ecosystem.config.js

echo "Deployment completed at $(date)" >> /var/log/deploy.log
```

```bash
# 设置权限
chmod +x ~/git/deploy.git/hooks/post-receive
chown deploy:deploy ~/git/deploy.git/hooks/post-receive
```

### 方式二：Nginx 配置 Webhook

```nginx
# /etc/nginx/conf.d/webhook.conf
server {
    listen 8080;
    server_name _;

    location /deploy {
        # 验证 secret token
        if ($http_x_webhook_secret != "your_secret_token") {
            return 403;
        }

        client_max_body_size 10M;

        location / {
            proxy_pass http://127.0.0.1:9000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

## PM2 自动部署脚本

```bash
#!/bin/bash
# deploy.sh

set -e

# 配置
APP_NAME="myapp"
APP_DIR="/var/www/myapp"
GIT_REPO="https://github.com/user/repo.git"
BRANCH="main"
SECRET_TOKEN="your_github_webhook_secret"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否为部署用户
check_user() {
    if [ "$USER" != "deploy" ]; then
        log_warn "Running as $USER, deployment user is 'deploy'"
    fi
}

# 备份当前版本
backup() {
    log_info "Backing up current version..."
    if [ -d "$APP_DIR" ]; then
        BACKUP_DIR="/var/backups/myapp/backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp -r "$APP_DIR" "$BACKUP_DIR/"
        log_success "Backup created at $BACKUP_DIR"
    fi
}

# 拉取代码
pull_code() {
    log_info "Pulling code from repository..."

    cd "$APP_DIR"

    # 配置 Git
    git config core.pager cat
    git config pull.rebase false

    # 拉取代码
    git pull origin "$BRANCH"

    log_success "Code pulled successfully"
}

# 安装依赖
install_deps() {
    log_info "Installing dependencies..."

    cd "$APP_DIR"

    if [ -f "package.json" ]; then
        npm ci --production
    fi

    log_success "Dependencies installed"
}

# 运行数据库迁移
run_migrations() {
    log_info "Running database migrations..."

    cd "$APP_DIR"

    if [ -f "node_modules/.bin/sequelize" ]; then
        node_modules/.bin/sequelize db:migrate
    elif [ -f "node_modules/.bin/knex" ]; then
        node_modules/.bin/knex migrate:latest
    fi

    log_success "Migrations completed"
}

# 重启应用
restart_app() {
    log_info "Restarting application..."

    pm2 restart "$APP_NAME" || pm2 start ecosystem.config.js

    log_success "Application restarted"
}

# 清理
cleanup() {
    log_info "Cleaning up..."

    # 删除旧备份 (保留最近 7 天)
    find /var/backups/myapp -type d -mtime +7 -exec rm -rf {} \;

    log_success "Cleanup completed"
}

# 发送通知
send_notification() {
    local status=$1
    local message=$2

    # 可以集成钉钉/企业微信/Slack 等通知
    # 这里以简单的 curl 通知为例

    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": {\"content\": \"[$status] $APP_NAME: $message\"}}" \
            2>/dev/null
    fi
}

# 主函数
main() {
    log_info "Starting deployment..."

    check_user
    backup
    pull_code
    install_deps
    run_migrations
    restart_app
    cleanup

    log_success "Deployment completed successfully!"
    send_notification "SUCCESS" "Deployment completed"
}

# 执行
main "$@"
```

## Docker 部署脚本

```bash
#!/bin/bash
# docker_deploy.sh

set -e

APP_NAME="myapp"
IMAGE_NAME="registry.example.com/$APP_NAME"
TAG=$(git rev-parse --short HEAD)
CONTAINER_NAME="$APP_NAME"

log_info() { echo "[INFO] $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_error() { echo "[ERROR] $1"; }

# 构建镜像
build_image() {
    log_info "Building Docker image..."

    docker build -t "$IMAGE_NAME:$TAG" .
    docker tag "$IMAGE_NAME:$TAG" "$IMAGE_NAME:latest"

    log_success "Image built: $IMAGE_NAME:$TAG"
}

# 推送到镜像仓库
push_image() {
    log_info "Pushing image to registry..."

    docker push "$IMAGE_NAME:$TAG"
    docker push "$IMAGE_NAME:latest"

    log_success "Image pushed"
}

# 部署到服务器
deploy() {
    log_info "Deploying to server..."

    # 拉取最新镜像
    docker pull "$IMAGE_NAME:latest"

    # 停止并删除旧容器
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    # 运行新容器
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:3000 \
        -e NODE_ENV=production \
        -v "$APP_NAME-data:/data" \
        "$IMAGE_NAME:latest"

    # 清理旧镜像
    docker image prune -f

    log_success "Deployment completed"
}

# 健康检查
health_check() {
    log_info "Running health check..."

    for i in {1..30}; do
        if curl -f http://localhost:8080/health >/dev/null 2>&1; then
            log_success "Health check passed"
            return 0
        fi
        sleep 2
    done

    log_error "Health check failed"
    return 1
}

# 回滚
rollback() {
    log_info "Rolling back to previous version..."

    docker pull "$IMAGE_NAME:$PREVIOUS_TAG"

    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:3000 \
        -e NODE_ENV=production \
        "$IMAGE_NAME:$PREVIOUS_TAG"

    log_success "Rollback completed"
}

# 主函数
main() {
    build_image
    push_image
    deploy
    health_check || {
        log_error "Health check failed, rolling back..."
        rollback
        exit 1
    }
}

main "$@"
```

## PM2 自动部署 (ecosystem deploy)

```javascript
// ecosystem.deploy.js
module.exports = {
  apps: [{
    name: 'myapp',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster'
  }],

  deploy: {
    production: {
      user: 'deploy',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'git@github.com:user/repo.git',
      path: '/var/www/myapp',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && pm2 restart myapp',
      'pre-setup': ''
    }
  }
};
```

```bash
# 设置部署配置
pm2 deploy ecosystem.deploy.js production setup

# 执行部署
pm2 deploy ecosystem.deploy.js production
```

## Cron 定时任务

```bash
# 打开 crontab
sudo crontab -e

# 示例定时任务
0 2 * * * /opt/backup.sh              # 每天凌晨 2 点备份
*/5 * * * * /opt/health_check.sh     # 每 5 分钟健康检查
0 3 * * 0 /opt/update.sh              # 每周日凌晨 3 点更新
```

## 健康检查脚本

```bash
#!/bin/bash
# health_check.sh

APP_URL="http://localhost:3000/health"
APP_NAME="myapp"

# 检查应用是否响应
if curl -sf "$APP_URL" >/dev/null; then
    echo "Application is healthy"
    exit 0
fi

# 如果 PM2 进程不存在，尝试重启
if ! pm2 info "$APP_NAME" >/dev/null 2>&1; then
    echo "Application not running, restarting..."
    pm2 start ecosystem.config.js

    sleep 10

    if curl -sf "$APP_URL" >/dev/null; then
        echo "Application restarted successfully"
        exit 0
    fi
fi

echo "Application is unhealthy"
exit 1
```

## GitHub Actions 部署示例

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Deploy to server
        uses: appleboy/ssh-action@v0.10.2
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
          script: |
            cd /var/www/myapp
            git pull origin main
            npm ci --production
            pm2 restart myapp
```

## 通知脚本 (钉钉/企业微信)

```bash
#!/bin/bash
# notify.sh

# 钉钉通知
send_dingtalk() {
    local token="$DINGTALK_TOKEN"
    local message="$1"

    curl -s -X POST "https://oapi.dingtalk.com/robot/send?access_token=$token" \
        -H "Content-Type: application/json" \
        -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"$message\"}}"
}

# 企业微信通知
send_wechat() {
    local webhook="$WECHAT_WEBHOOK"
    local message="$1"

    curl -s -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"$message\"}}"
}

# 使用示例
send_dingtalk "[Deploy] myapp deployed successfully at $(date)"
```
