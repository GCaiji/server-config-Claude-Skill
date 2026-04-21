# 防火墙配置指南

## 概述

| 防火墙 | 适用系统 | 说明 |
|--------|----------|------|
| UFW | Ubuntu/Debian | 简单易用的防火墙工具 |
| firewalld | CentOS/Rocky/AlmaLinux | 动态防火墙管理工具 |
| iptables | 所有 Linux | 传统的包过滤防火墙 |

## UFW (Ubuntu/Debian)

### 安装与启用

```bash
# 检查 UFW 状态
sudo ufw status

# 启用 UFW
sudo ufw enable

# 禁用 UFW
sudo ufw disable

# 重置 UFW (恢复默认设置)
sudo ufw reset
```

### 基本规则

```bash
# 允许 SSH (防止锁在外面)
sudo ufw allow 22/tcp

# 允许 HTTP 和 HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许特定端口范围
sudo ufw allow 8000:9000/tcp

# 允许来自特定 IP
sudo ufw allow from 192.168.1.100

# 允许特定 IP 的特定端口
sudo ufw allow from 192.168.1.100 to any port 22

# 拒绝连接
sudo ufw deny 3306/tcp

# 删除规则
sudo ufw delete allow 80/tcp
sudo ufw delete rule '22/tcp'
```

### 应用配置

```bash
# 查看可用应用
sudo ufw app list

# 查看 Nginx 配置
sudo ufw app info 'Nginx Full'

# 允许 Nginx (完整配置 - HTTP + HTTPS)
sudo ufw allow 'Nginx Full'

# 允许 OpenSSH
sudo ufw allow 'OpenSSH'
```

### IP 伪装 (端口转发)

```bash
# 启用 IP 转发
sudo nano /etc/ufw/sysctl.conf

# 修改或添加
net/ipv4/ip_forward=1
net/ipv6/ip_forward=1

# 添加 NAT 规则
sudo ufw route allow in on eth0 out on eth1
```

### 查看规则

```bash
# 查看状态和规则
sudo ufw status verbose

# 编号显示
sudo ufw status numbered

# 查看详细日志
sudo ufw audit logfile
```

### 日志配置

```bash
# 查看日志
sudo tail -f /var/log/ufw.log

# 设置日志级别
sudo ufw logging off         # 关闭
sudo ufw logging low         # 低 - 只记录拒绝的连接
sudo ufw logging medium      # 中 - 记录被阻止的连接和无效包
sudo ufw logging high       # 高 - 记录所有被阻止的连接
sudo ufw logging full       # 完全 - 所有规则匹配
```

## firewalld (CentOS/Rocky/AlmaLinux)

### 基本命令

```bash
# 检查状态
sudo firewall-cmd --state

# 查看默认区域
sudo firewall-cmd --get-default-zone

# 查看活跃区域
sudo firewall-cmd --get-active-zones

# 查看区域的规则
sudo firewall-cmd --zone=public --list-all

# 查看所有可用服务
sudo firewall-cmd --get-services
```

### 端口管理

```bash
# 开放端口 (临时 - 重启失效)
sudo firewall-cmd --add-port=80/tcp
sudo firewall-cmd --add-port=8000-9000/tcp

# 开放端口 (永久)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=80/tcp --zone=public

# 关闭端口
sudo firewall-cmd --remove-port=80/tcp
sudo firewall-cmd --permanent --remove-port=80/tcp

# 重新加载配置 (修改后需要)
sudo firewall-cmd --reload

# 查看已开放的端口
sudo firewall-cmd --list-ports
```

### 服务管理

```bash
# 开放服务
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh

# 关闭服务
sudo firewall-cmd --permanent --remove-service=http

# 查看已开放的服务
sudo firewall-cmd --list-services
```

### 区域管理

```bash
# 设置默认区域
sudo firewall-cmd --set-default-zone=public

# 添加接口到区域
sudo firewall-cmd --permanent --zone=trusted --change-interface=eth0

# 添加来源 IP 到区域
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.1.0/24
```

### 富规则 (高级配置)

```bash
# 只允许特定 IP 访问 SSH
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.100" service name="ssh" accept'

# 拒绝特定 IP
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.200" drop'

# 限制连接数
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="http" limit value="50/m" accept'

# 查看富规则
sudo firewall-cmd --list-rich-rules
```

### IP 伪装 (端口转发)

```bash
# 启用 IP 伪装
sudo firewall-cmd --permanent --add-masquerade

# 端口转发 (本机 80 -> 192.168.1.100:8080)
sudo firewall-cmd --permanent --add-forward-port=port=80:proto=tcp:toport=8080:toaddr=192.168.1.100

# 删除转发规则
sudo firewall-cmd --permanent --remove-forward-port=port=80:proto=tcp:toport=8080:toaddr=192.168.1.100

# 重新加载
sudo firewall-cmd --reload
```

## iptables (通用)

### 基本命令

```bash
# 查看规则
sudo iptables -L -n -v

# 清空规则
sudo iptables -F
sudo iptables -X
sudo iptables -Z

# 设置默认策略
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
```

### 基本规则

```bash
# 允许本地回环
sudo iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许 HTTP/HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许特定 IP
sudo iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# 拒绝连接
sudo iptables -A INPUT -p tcp --dport 3306 -j DROP

# 删除规则 (查看编号后)
sudo iptables -L -n --line-numbers
sudo iptables -D INPUT 3
```

### 保存规则

```bash
# Debian/Ubuntu
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload

# CentOS/Rocky/Alma
sudo service iptables save
# 或
sudo iptables-save > /etc/sysconfig/iptables
```

### iptables 脚本示例

```bash
#!/bin/bash
# firewall_setup.sh

# 清空现有规则
iptables -F
iptables -X
iptables -Z

# 设置默认策略
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许本地回环
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许 SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许 HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许 ping (可选)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 记录被拒绝的连接 (可选)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 7

# 拒绝其他所有输入
iptables -A INPUT -j DROP

echo "Firewall rules applied successfully"
```

## 常用端口参考

| 端口 | 协议 | 服务 | 说明 |
|------|------|------|------|
| 22 | TCP | SSH | 远程连接 |
| 80 | TCP | HTTP | Web 服务 |
| 443 | TCP | HTTPS | 安全 Web |
| 3306 | TCP | MySQL | 数据库 |
| 5432 | TCP | PostgreSQL | 数据库 |
| 6379 | TCP | Redis | 缓存 |
| 27017 | TCP | MongoDB | 数据库 |
| 2375 | TCP | Docker | Docker API |
| 3000 | TCP | Node.js | 应用端口 |

## 安全建议

1. **只开放必要的端口** - 如果不使用数据库，不要开放 3306 等端口
2. **限制 SSH 来源** - 使用 `--add-source` 限制可 SSH 登录的 IP
3. **使用密钥认证** - 禁用密码登录 SSH
4. **启用日志** - 开启防火墙日志以便监控
5. **定期检查规则** - 定期审查防火墙规则
6. **测试后应用** - 在测试环境中验证规则后再应用

## 云服务器安全组配置

腾讯云和阿里云需要在控制台配置**安全组**，与系统防火墙配合使用：

### 腾讯云安全组规则

```
入站规则:
- 来源: 0.0.0.0/0  协议: TCP  端口: 80,443
- 来源: 你的IP      协议: TCP  端口: 22

出站规则:
- 策略: 全部允许
```

### 阿里云安全组规则

```
入方向:
- 授权策略: 允许  协议: TCP  端口: 80/80  授权对象: 0.0.0.0/0
- 授权策略: 允许  协议: TCP  端口: 443/443 授权对象: 0.0.0.0/0
- 授权策略: 允许  协议: TCP  端口: 22/22  授权对象: 你的IP/32
```
