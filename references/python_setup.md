# Python 环境安装与配置指南

## 支持的操作系统

| 发行版 | 安装命令 |
|--------|----------|
| Ubuntu/Debian | `apt-get install python3 python3-pip` |
| CentOS/Rocky/AlmaLinux | `yum install python3 python3-pip` |

## 安装 Python

### Ubuntu 20.04+

```bash
# 安装 Python3 和 pip
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv

# 验证版本
python3 --version
pip3 --version
```

### Ubuntu 22.04+

```bash
# 默认已安装 Python 3.10+
python3 --version
pip3 --version

# 安装 pip 和 venv
sudo apt-get install python3-pip python3-venv python3-full

# 设置 pip 加速 (腾讯镜像)
pip3 config set global.index-url https://mirr.tencent.com/pypi/simple/
```

### CentOS 7

```bash
# 安装 IUS 源获取更新版本的 Python
sudo yum install epel-release
sudo yum install https://centos7.iuscommunity.org/ius-release.rpm

# 安装 Python 3.11
sudo yum install python311u python311u-pip python311u-devel

# 创建软链接
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3
sudo ln -sf /usr/bin/pip3.11 /usr/bin/pip3
```

### Rocky Linux 8+ / AlmaLinux 8+

```bash
# 使用 AppStream
sudo dnf module reset python
sudo dnf module enable python:3.11
sudo dnf module install python

# 验证
python3 --version
pip3 --version
```

## 配置虚拟环境

### 使用 venv (推荐)

```bash
# 创建虚拟环境
python3 -m venv myproject/venv

# 激活虚拟环境
source myproject/venv/bin/activate

# 退出虚拟环境
deactivate
```

### 使用 pyenv (多版本管理)

```bash
# 安装 pyenv 依赖
sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
    libffi-dev liblzma-dev

# 安装 pyenv
curl https://pyenv.run | bash

# 配置 shell (添加到 ~/.bashrc)
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# 重新加载
source ~/.bashrc

# 安装 Python 版本
pyenv install 3.11.0
pyenv install 3.10.0

# 设置全局版本
pyenv global 3.11.0

# 在项目目录使用特定版本
cd myproject
pyenv local 3.10.0
```

## pip 配置

### 全局配置

```bash
# 设置腾讯镜像
pip3 config set global.index-url https://mirr.tencent.com/pypi/simple/

# 设置阿里云镜像
pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/

# 设置清华镜像
pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/

# 验证
pip3 config list
```

### 项目级配置 (requirements.txt)

```bash
# 创建虚拟环境 (如果需要离线)
python3 -m venv venv
source venv/bin/activate

# 生成依赖文件
pip freeze > requirements.txt

# 从依赖文件安装
pip install -r requirements.txt
```

## 常用 Python 包安装

```bash
# Flask (轻量 Web 框架)
pip install flask

# Django (重量级 Web 框架)
pip install django

# FastAPI (现代高性能框架)
pip install fastapi uvicorn

# 数据库
pip install mysql-connector-python
pip install psycopg2-binary
pip install pymongo
pip install redis

# 工具库
pip install requests
pip install beautifulsoup4
pip install lxml
pip install pandas
pip install numpy

# Web 服务器
pip install gunicorn
pip install gevent
```

## Gunicorn 配置

```ini
# gunicorn_config.py
import multiprocessing

bind = "127.0.0.1:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "gevent"
worker_connections = 1000
max_requests = 10000
max_requests_jitter = 1000
timeout = 30
keepalive = 2
```

```bash
# 启动命令
gunicorn -c gunicorn_config.py app:app

# 或命令行直接指定
gunicorn -w 4 -b 127.0.0.1:8000 app:app
```

## Systemd 服务配置

```ini
# /etc/systemd/system/python-app.service
[Unit]
Description=Python Application
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/var/www/myapp
Environment="PATH=/var/www/myapp/venv/bin"
ExecStart=/var/www/myapp/venv/bin/gunicorn -c /var/www/myapp/gunicorn_config.py app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable python-app
sudo systemctl start python-app
sudo systemctl status python-app
```

## 常见问题排查

```bash
# 检查 Python 版本
python3 --version

# 检查 pip 版本
pip3 --version

# 升级 pip
pip3 install --upgrade pip

# 检查已安装的包
pip3 list

# 解决权限问题 (不要用 sudo pip)
pip3 install --user package_name

# 设置正确路径
export PATH="$HOME/.local/bin:$PATH"
```
