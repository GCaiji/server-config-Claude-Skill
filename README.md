# server-config

> Claude Code 服务器自动化配置技能 - 让服务器配置和部署变得简单高效

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude](https://img.shields.io/badge/Claude-Code-green.svg)](https://claude.ai)

---

## 功能特点

- **多云支持**：支持腾讯云、阿里云、AWS 等主流云服务器
- **多系统适配**：Ubuntu、Debian、CentOS、Rocky Linux、AlmaLinux 等
- **一键环境配置**：Nginx、Apache、PHP、Python、Node.js
- **数据库支持**：MySQL、PostgreSQL、MongoDB、Redis
- **Docker 部署**：容器化部署和管理
- **SSL 证书**：Let's Encrypt 免费证书自动配置
- **安全加固**：防火墙、SSH 安全、Fail2Ban 等
- **自动化部署**：支持 PM2、Git Hooks、Webhook 等多种部署方式

---

## 安装步骤

### 方法一：通过 Git 安装（推荐）

#### 1. 克隆仓库

```bash
# 克隆到 Skills 目录
git clone https://github.com/GCaiji/server-config-Claude-Skill.git ~/.claude/skills/server-config

# 或者如果你已经有其他 skills
cd ~/.claude/skills
git clone https://github.com/GCaiji/server-config-Claude-Skill.git server-config
```

#### 2. 验证安装

```bash
# 检查目录结构
ls -la ~/.claude/skills/server-config/

# 应该看到以下内容
# .
# ├── SKILL.md
# ├── scripts/
# │   └── detect_os.sh
# └── references/
#     ├── apache_setup.md
#     ├── deployment.md
#     ├── docker_setup.md
#     ├── firewall.md
#     ├── mongodb_setup.md
#     ├── mysql_setup.md
#     ├── nginx_setup.md
#     ├── nodejs_setup.md
#     ├── php_setup.md
#     ├── postgresql_setup.md
#     ├── python_setup.md
#     ├── project_deploy.md
#     ├── redis_setup.md
#     ├── security.md
#     └── ssl_setup.md
```

#### 3. 立即使用

在 Claude Code 中直接说出你的需求：

```
# 配置服务器
用户：帮我配置一个新的云服务器

# 部署应用
用户：部署一个 Node.js 应用到服务器

# 安装环境
用户：在服务器上安装 Nginx 和 PHP

# 配置 SSL
用户：帮我配置 SSL 证书
```

---

### 方法二：手动下载安装

#### 1. 下载最新版本

访问 [GitHub Releases](https://github.com/GCaiji/server-config-Claude-Skill/releases) 下载 `server-config.zip`

#### 2. 解压到 Skills 目录

```bash
# Windows (PowerShell)
Expand-Archive -Path server-config.zip -DestinationPath "$env:USERPROFILE\.claude\skills\server-config"

# Linux/macOS
unzip server-config.zip -d ~/.claude/skills/
mv ~/.claude/skills/server-config-* ~/.claude/skills/server-config
```

#### 3. 验证安装

重启 Claude Code 或发送新消息，skill 会自动加载。

---

### 方法三：通过 Claude Code 命令安装

如果你正在使用 Claude Code 并且有权限执行命令：

```
# 在 Claude Code 中直接执行
请帮我把 https://github.com/GCaiji/server-config-Claude-Skill.git 这个仓库安装到 skills 目录
```

---

## 使用方法

### 基础使用

在 Claude Code 中直接说出你的需求，skill 会自动检测并执行：

```
# 示例 1：配置新服务器
用户：我在腾讯云买了一台 Ubuntu 22.04 的服务器，帮我配置好环境

# 示例 2：部署应用
用户：把 Monopoly 后端部署到生产服务器

# 示例 3：配置 SSL
用户：帮我给 example.com 配置 SSL 证书
```

### 项目部署配置

#### 什么是 PROJECT_DEPLOY.md？

每个需要部署的项目都应该有一份 `PROJECT_DEPLOY.md` 配置文件。skill 会在部署前检查此文件，根据配置进行自动化部署。

#### 部署流程

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
│  - 读取技术栈要求       │    │  1. 探索项目结构                          │
│  - 获取环境变量        │    │  2. 识别编程语言和框架                     │
│  - 连接数据库/Redis    │    │  3. 查找数据库配置                        │
│  - 执行部署            │    │  4. 记录编译命令                          │
│                         │    │  5. 记录环境变量                          │
│                         │    │  6. 生成 PROJECT_DEPLOY.md                │
└─────────────────────────┘    └─────────────────────────────────────────┘
```

#### 创建项目配置

让 Claude Code 帮你创建：

```
用户：帮我为 monopoly-backend 项目创建部署配置
```

---

## 目录结构

```
server-config/
├── SKILL.md                      # 技能主文件（必需）
├── scripts/
│   └── detect_os.sh              # 操作系统检测脚本
└── references/
    ├── project_deploy.md        # 项目部署配置模板
    ├── nginx_setup.md           # Nginx 安装配置
    ├── apache_setup.md          # Apache 安装配置
    ├── php_setup.md             # PHP 环境配置
    ├── python_setup.md          # Python 环境配置
    ├── nodejs_setup.md          # Node.js 环境配置
    ├── mysql_setup.md           # MySQL/MariaDB 配置
    ├── postgresql_setup.md      # PostgreSQL 配置
    ├── mongodb_setup.md         # MongoDB 配置
    ├── redis_setup.md           # Redis 配置
    ├── docker_setup.md          # Docker 配置
    ├── ssl_setup.md             # SSL 证书配置
    ├── firewall.md              # 防火墙配置
    ├── security.md              # 安全加固指南
    └── deployment.md            # 自动化部署脚本
```

---

## 支持的操作系统

| 发行版 | 版本 | 状态 |
|--------|------|------|
| Ubuntu | 20.04+ | ✅ 支持 |
| Ubuntu | 18.04 | ✅ 支持 |
| Debian | 11+ | ✅ 支持 |
| Debian | 10 | ✅ 支持 |
| CentOS | 7 | ✅ 支持 |
| CentOS | 8+ | ✅ 支持 |
| Rocky Linux | 8+ | ✅ 支持 |
| AlmaLinux | 8+ | ✅ 支持 |

---

## 支持的服务

| 类型 | 服务 |
|------|------|
| **Web 服务器** | Nginx, Apache |
| **编程语言** | PHP 7.4+, Python 3.6+, Node.js 14+ |
| **数据库** | MySQL 8.0, PostgreSQL 13+, MongoDB 6.0+, Redis 7.0+ |
| **容器** | Docker 20.10+, Docker Compose |

---

## 常见问题

### Q: 如何更新 skill 到最新版本？

```bash
cd ~/.claude/skills/server-config
git pull origin main
```

### Q: skill 不会自动触发？

确保你的 Claude Code 可以访问 Skills 目录。你可以手动输入需求来触发：

```
用户：帮我配置服务器环境
```

### Q: 如何查看支持的功能？

查看 `SKILL.md` 文件或向 Claude Code 询问：

```
用户：这个 skill 支持哪些功能？
```

---

## 贡献

欢迎提交 Issue 和 Pull Request！

---

## 许可证

本项目采用 [MIT License](LICENSE) 许可证。

---

## 作者

- **GitHub**: [GCaiji](https://github.com/GCaiji)
- **主页**: [Claude Code Skills](https://github.com/GCaiji/server-config-Claude-Skill)

---

**如果你觉得这个 skill 有用，请 Star ⭐ 支持一下喵~ 💕**
