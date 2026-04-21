# 服务器安全加固指南

## SSH 安全配置

### 禁用密码登录，使用密钥

```bash
# 在本地生成 SSH 密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 上传公钥到服务器
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@server_ip

# 测试密钥登录后再禁用密码登录
ssh root@server_ip

# 编辑 SSH 配置
sudo nano /etc/ssh/sshd_config
```

```ini
# /etc/ssh/sshd_config

# 禁止 root 登录
PermitRootLogin no

# 禁止密码认证
PasswordAuthentication no

# 禁止空密码
PermitEmptyPasswords no

# 使用 SSH 密钥
PubkeyAuthentication yes

# 更改默认端口 (可选)
Port 2222

# 限制最大连接尝试次数
MaxAuthTries 3

# 禁用无用的认证方法
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no

# 设置空闲超时
ClientAliveInterval 300
ClientAliveCountMax 2

# 禁用 X11 转发
X11Forwarding no
```

```bash
# 重启 SSH 服务
sudo systemctl restart sshd
sudo systemctl restart ssh

# 重要：保留一个 SSH 会话，以防配置错误导致无法登录
```

### 限制 SSH 访问 IP

```bash
# 方法一：使用 UFW (Ubuntu/Debian)
sudo ufw allow from 你的IP to any port 22

# 方法二：使用 firewalld (CentOS/Rocky/Alma)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="你的IP/32" service name="ssh" accept'

# 方法三：使用 tcp wrappers
sudo nano /etc/hosts.allow
sshd: 你的IP
sudo nano /etc/hosts.deny
sshd: ALL
```

## 用户权限管理

### 创建普通用户

```bash
# 创建新用户
sudo adduser deploy

# 添加到 sudo 组 (Debian/Ubuntu)
sudo usermod -aG sudo deploy

# 添加到 wheel 组 (CentOS/Rocky/Alma)
sudo usermod -aG wheel deploy

# 切换用户
su - deploy
```

### 禁用不必要的用户

```bash
# 查看系统用户
cat /etc/passwd | grep -v nologin | grep -v false

# 禁用特定用户
sudo usermod -L username

# 禁止用户使用 SSH
sudo usermod -s /sbin/nologin username
```

### sudo 权限配置

```bash
# 编辑 sudoers 文件 (避免语法错误)
sudo visudo

# 允许特定用户无密码 sudo
deploy ALL=(ALL) NOPASSWD: ALL

# 允许特定用户使用特定命令
deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/systemctl restart php-fpm

# 不允许 sudo su -
deploy ALL=(ALL) ALL, !/usr/bin/su
```

## 系统更新

### Ubuntu/Debian

```bash
# 更新软件包列表
sudo apt-get update

# 升级所有软件
sudo apt-get upgrade -y

# 升级系统版本
sudo do-release-upgrade

# 自动安全更新
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### CentOS/Rocky/AlmaLinux

```bash
# 更新所有软件
sudo yum update -y

# 启用自动更新
sudo yum install dnf-automatic
sudo systemctl enable dnf-automatic.timer
```

## 文件系统安全

### 设置文件权限

```bash
# 锁定重要文件
sudo chattr +i /etc/passwd
sudo chattr +i /etc/shadow
sudo chattr +i /etc/group
sudo chattr +i /etc/gshadow

# 解锁 (需要时)
sudo chattr -i /etc/passwd

# 查看特殊属性
lsattr /etc/passwd
```

### 限制文件和目录权限

```bash
# 网站目录
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/uploads

# SSH 密钥
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys

# 敏感配置文件
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 600 /etc/nginx/nginx.conf
```

## 服务安全

### 禁用不必要的服务

```bash
# 查看运行中的服务
sudo systemctl list-units --type=service --state=running

# 停止并禁用服务
sudo systemctl stop telnet.socket
sudo systemctl disable telnet.socket
sudo systemctl mask telnet.socket

# 检查开机启动项
sudo systemctl list-unit-files | grep enabled
```

### 安装和使用 Fail2Ban

Fail2Ban 自动封禁恶意登录尝试的 IP。

```bash
# Ubuntu/Debian
sudo apt-get install fail2ban

# CentOS/Rocky/Alma
sudo yum install fail2ban
sudo dnf install fail2ban

# 启动并启用
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
# 封禁时间 (秒)
bantime = 3600
# 查找时间窗口 (秒)
findtime = 600
# 最大尝试次数
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
```

```bash
# 重启服务
sudo systemctl restart fail2ban

# 查看状态
sudo fail2ban-client status
sudo fail2ban-client status sshd

# 解封 IP
sudo fail2ban-client set sshd unbanip 192.168.1.100
```

## 系统日志监控

### 重要日志文件

| 日志文件 | 说明 |
|----------|------|
| `/var/log/auth.log` | 认证日志 (Ubuntu) |
| `/var/log/secure` | 认证日志 (CentOS) |
| `/var/log/nginx/access.log` | Nginx 访问日志 |
| `/var/log/nginx/error.log` | Nginx 错误日志 |
| `/var/log/mysql/error.log` | MySQL 错误日志 |

### 常用监控命令

```bash
# 查看 SSH 登录尝试
sudo grep "Accepted" /var/log/auth.log
sudo grep "Failed" /var/log/auth.log

# 查看最近登录记录
last
lastlog

# 查看当前登录用户
who

# 查看系统登录统计
sudo ac -p

# 监控实时日志
sudo tail -f /var/log/auth.log
```

## 网络安全

### 配置 sysctl 参数

```ini
# /etc/sysctl.conf

# 禁用 IP 转发
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# 禁用 ICMP 重定向
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# 启用 SYN Cookies (防止 SYN 洪水攻击)
net.ipv4.tcp_syncookies = 1

# 禁用源路由
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# 启用恶意 ICMP 报文过滤
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_invalid_error = 1

# 调整内核参数
kernel.exec-shield = 1
kernel.randomize_va_space = 2
```

```bash
# 应用更改
sudo sysctl -p
```

## rootkit 检测

### 安装和使用 rkhunter

```bash
# 安装
sudo apt-get install rkhunter   # Ubuntu/Debian
sudo yum install rkhunter      # CentOS

# 更新数据库
sudo rkhunter --update

# 运行检查
sudo rkhunter --check

# 查看报告
sudo rkhunter --check --report-warnings-only
```

### 安装和使用 chkrootkit

```bash
# 安装
sudo apt-get install chkrootkit  # Ubuntu/Debian
sudo yum install chkrootkit     # CentOS

# 运行检查
sudo chkrootkit
```

## 系统审计

### 安装 auditd

```bash
# 安装
sudo apt-get install auditd   # Ubuntu/Debian
sudo yum install audit       # CentOS

# 启动
sudo systemctl start auditd
sudo systemctl enable auditd
```

```ini
# /etc/audit/audit.rules

# 记录文件变更
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/ssh/sshd_config -p wa -k sshd_config

# 记录命令执行
-a exit,always -F arch=b64 -S execve
```

## 文件完整性检查

### AIDE (高级入侵检测环境)

```bash
# 安装
sudo apt-get install aide   # Ubuntu/Debian
sudo yum install aide       # CentOS

# 初始化数据库
sudo aideinit

# 移动数据库
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# 运行检查
sudo aide --check

# 更新数据库
sudo aide --update
sudo aide --update
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
```

## 安全检查清单

- [ ] 修改 SSH 默认端口
- [ ] 禁用 root SSH 登录
- [ ] 使用 SSH 密钥认证
- [ ] 限制 SSH 访问 IP
- [ ] 配置防火墙
- [ ] 安装 Fail2Ban
- [ ] 禁用不必要的服务
- [ ] 保持系统更新
- [ ] 配置文件权限
- [ ] 启用日志记录
- [ ] 安装 rootkit 检测工具
- [ ] 配置 sysctl 安全参数
- [ ] 备份重要数据
