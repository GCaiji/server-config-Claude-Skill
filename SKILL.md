---
name: server-config
description: 服务器自动化配置技能。适用于在腾讯云、阿里云或其他主流云服务器上进行环境配置、安全设置、Nginx/Apache、PHP/Python/Node.js、数据库、Docker、SSL 证书等自动化部署和配置。当用户需要搭建网站运行环境、配置服务器安全、安装数据库、配置 SSL、自动化部署等项目时触发。
---

# Server Config - 服务器自动化配置技能

本 skill 提供服务器自动化配置能力，支持腾讯云、阿里云等主流云服务器，覆盖 Ubuntu、CentOS、Debian 等主流 Linux 发行版。

## 核心能力

- 系统环境检测与适配
- Web 服务器配置（Nginx/Apache）
- 多种语言运行环境（Go/PHP/Python/Node.js）
- 数据库安装与配置（MySQL/PostgreSQL/MongoDB/Redis）
- Docker 容器化部署
- SSL 证书配置（Let's Encrypt/Nginx 配置）
- 防火墙与安全加固
- 自动化部署脚本生成

## 项目部署配置检查流程

> **重要**：部署前必须检查项目部署配置，杜绝盲目探索！

### 部署流程

```
┌─────────────────────────────────────────────────────────────┐
│                     部署请求                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: 检查 PROJECT_DEPLOY.md                             │
│  在项目根目录查找项目部署配置文件                            │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
         存在                              不存在
              │                               │
              ▼                               ▼
┌─────────────────────────┐    ┌─────────────────────────────────────────┐
│  使用已有配置部署        │    │  创建项目部署配置                          │
│                         │    │                                          │
│  - 读取技术栈要求       │    │  1. 探索项目结构                          │
│  - 获取环境变量        │    │  2. 识别编程语言和框架                     │
│  - 连接数据库/Redis    │    │  3. 查找数据库配置                        │
│  - 执行部署            │    │  4. 记录编译命令                          │
│                         │    │  5. 记录环境变量                          │
│  参考: references/     │    │  6. 生成 PROJECT_DEPLOY.md                │
│  project_deploy.md     │    │                                          │
└─────────────────────────┘    └─────────────────────────────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 2: 环境检测                                         │
│  - 检测操作系统                                          │
│  - 检查依赖服务状态                                       │
│  - 验证环境变量                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 3: 执行部署                                         │
│  - 编译或使用预编译二进制                                 │
│  - 配置环境变量                                           │
│  - 启动服务                                               │
│  - 健康检查                                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 4: 验证部署                                          │
│  - 健康检查接口测试                                        │
│  - 日志检查                                               │
│  - 报告部署结果                                            │
└─────────────────────────────────────────────────────────────┘
```

### PROJECT_DEPLOY.md 配置模板

项目根目录应包含 `PROJECT_DEPLOY.md`，包含以下内容：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 项目基本信息 | 名称、仓库、负责人 | monopoly-backend |
| 技术栈 | 语言、版本、框架 | Go 1.21+, Gin, MySQL 8.0 |
| 目录结构 | 关键文件和目录 | main.go, config/ |
| 编译配置 | 编译命令、注意事项 | `go build main.go` |
| 环境变量 | 必需的配置项 | PORT, JWT_SECRET 等 |
| 依赖服务 | Docker 容器信息 | MySQL, Redis 容器和连接信息 |
| 端口配置 | 端口分配和策略 | 8082 |
| 健康检查 | 检查接口 | GET /health |

详细模板参考：`references/project_deploy.md`

### 禁止行为

- 部署前不检查配置文档
- 每次部署都重新探索项目结构
- 手动查找数据库密码和连接信息
- 反复尝试端口直到成功
- 不使用预编译二进制而尝试重新编译

### 配置检查清单

- [ ] 项目根目录有 PROJECT_DEPLOY.md
- [ ] 技术栈和版本要求明确
- [ ] 环境变量列表完整
- [ ] 数据库连接信息已记录
- [ ] 编译命令已记录
- [ ] 端口分配已确定

## 使用流程

### Step 1: 连接服务器

使用 SSH 连接到目标服务器：

```bash
ssh root@服务器IP -p 端口号
# 或使用密钥文件
ssh -i ~/.ssh/your-key.pem root@服务器IP
```

### Step 2: 检查项目部署配置

1. **检查项目根目录是否有 PROJECT_DEPLOY.md**
2. **如果有**：直接使用配置的编译命令、环境变量、端口
3. **如果没有**：按照以下顺序探索项目：
   - 查看 `go.mod` / `package.json` / `pom.xml` 等确定技术栈
   - 查看配置文件获取数据库连接信息
   - 查看入口文件确定编译命令
   - **创建 PROJECT_DEPLOY.md 保存配置**

### Step 3: 检测操作系统

执行 `scripts/detect_os.sh` 或手动检测：

```bash
# 手动检测方法
cat /etc/os-release          # 查看发行版信息
uname -a                     # 查看内核信息
which systemctl              # 判断 init 系统
```

参考 `references/detect_os.md` 获取各系统差异。

### Step 4: 选择配置方案

根据用户需求，选择对应的配置模块：

| 需求 | 参考文档 |
|------|---------|
| 项目部署配置模板 | `references/project_deploy.md` |
| API 网关与 Nginx 反向代理 | `references/nginx_api_gateway.md` |
| Go 环境配置 | `references/go_setup.md` |
| Nginx 安装配置 | `references/nginx_setup.md` |
| Apache 安装配置 | `references/apache_setup.md` |
| PHP 环境 | `references/php_setup.md` |
| Python 环境 | `references/python_setup.md` |
| Node.js 环境 | `references/nodejs_setup.md` |
| MySQL 数据库 | `references/mysql_setup.md` |
| PostgreSQL 数据库 | `references/postgresql_setup.md` |
| MongoDB 数据库 | `references/mongodb_setup.md` |
| Redis 缓存 | `references/redis_setup.md` |
| Docker 安装 | `references/docker_setup.md` |
| SSL 证书配置 | `references/ssl_setup.md` |
| 防火墙配置 | `references/firewall.md` |
| 安全加固 | `references/security.md` |
| 自动化部署 | `references/deployment.md` |

### Step 5: 生成配置脚本

根据检测到的操作系统和项目配置，从参考文档中提取相应的配置命令，生成可执行的脚本。

### Step 6: 记录配置信息

将服务器配置信息记录到 `references/server_info.md`（如果用户需要持久化保存）。

## 操作系统支持矩阵

| 发行版 | 版本 | Nginx | Apache | PHP | Python | Node.js | MySQL | Docker |
|--------|------|-------|--------|-----|--------|---------|-------|--------|
| Ubuntu | 20.04+ | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Ubuntu | 18.04 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| CentOS | 7 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| CentOS | 8+ | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Rocky Linux | 8+ | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Debian | 11+ | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |
| Debian | 10 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 | 支持 |

## 安全注意事项

1. **生产环境操作前请备份** - 操作数据库、修改配置文件前先备份
2. **权限最小化** - 不要使用 root 运行应用服务
3. **防火墙规则** - 只开放必要的端口（80, 443, 22）
4. **SSH 密钥** - 优先使用 SSH 密钥登录，禁用密码登录
5. **SSL 证书** - 生产环境必须使用有效的 SSL 证书

## 常用检查命令

```bash
# 系统信息
cat /etc/os-release
free -h                    # 内存使用
df -h                      # 磁盘使用

# 服务状态
systemctl status nginx
systemctl status mysql
docker ps

# 端口监听
netstat -tlnp
ss -tlnp

# 日志位置
/var/log/nginx/
/var/log/mysql/
journalctl -u 服务名
```
