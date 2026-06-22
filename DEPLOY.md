# 学生宿舍管理系统 — 腾讯云部署指南

## 前期准备

| 项目 | 说明 |
|------|------|
| 云服务器 | 腾讯云 CVM / 轻量应用服务器（Ubuntu 18.04 / 20.04 / 22.04） |
| GitHub 仓库 | https://github.com/L1nZzz166/dormitory-management-system |
| 安全组 | 开放 **80 端口（HTTP）**和 **22 端口（SSH）** |

> ⚠️ 在腾讯云控制台 → 安全组 → 添加入站规则 → 放行 TCP 80 端口

---

## 方法一：一键部署（推荐）

### 第 1 步：SSH 登录服务器

```bash
ssh root@你的服务器公网IP
```

### 第 2 步：运行部署脚本

```bash
# 克隆项目
git clone https://github.com/L1nZzz166/dormitory-management-system.git
cd dormitory-management-system

# 赋予执行权限并运行
chmod +x deploy.sh
bash deploy.sh --ip 你的服务器公网IP
```

部署脚本会自动完成：
- ✅ 安装 Python3 + pip + nginx + git
- ✅ 创建虚拟环境并安装依赖
- ✅ 初始化数据库 + 加载种子数据
- ✅ 创建登录账号
- ✅ 配置 Nginx 反向代理
- ✅ 设置 systemd 开机自启

### 第 3 步：浏览器访问

```
http://你的服务器公网IP
```

---

## 方法二：手动逐步部署

### 第 1 步：SSH 登录并安装基础软件

```bash
ssh root@你的服务器公网IP

# 更新系统
sudo apt-get update

# 安装依赖
sudo apt-get install -y python3 python3-pip python3-venv nginx git
```

### 第 2 步：克隆项目并创建虚拟环境

```bash
sudo mkdir -p /opt/dormitory_management
sudo chown -R $USER:$USER /opt/dormitory_management
cd /opt/dormitory_management

git clone https://github.com/L1nZzz166/dormitory-management-system.git .

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 第 3 步：初始化数据库

```bash
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python create_user.py          # 创建登录账号
python seed_data.py             # 加载演示数据
```

### 第 4 步：配置 Nginx

```bash
sudo nano /etc/nginx/sites-available/dormitory
```

写入以下内容（替换 `YOUR_IP` 为你的服务器 IP）：

```nginx
server {
    listen 80;
    server_name YOUR_IP;

    location /static/ {
        alias /opt/dormitory_management/static/;
        expires 30d;
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

启用配置：

```bash
sudo ln -sf /etc/nginx/sites-available/dormitory /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

### 第 5 步：配置 systemd 服务

```bash
sudo nano /etc/systemd/system/dormitory.service
```

写入：

```ini
[Unit]
Description=学生宿舍管理系统 Gunicorn
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/opt/dormitory_management
Environment="PATH=/opt/dormitory_management/venv/bin"
ExecStart=/opt/dormitory_management/venv/bin/gunicorn \
    --workers 3 \
    --bind 127.0.0.1:8001 \
    --timeout 60 \
    dormitory_management.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable dormitory
sudo systemctl start dormitory
```

### 第 6 步：检查运行

```bash
sudo systemctl status dormitory   # 查看状态
sudo systemctl status nginx       # 查看 nginx
sudo journalctl -u dormitory -f   # 查看实时日志
```

浏览器打开 `http://你的服务器公网IP`

---

## 日常管理命令

```bash
# 查看服务状态
sudo systemctl status dormitory

# 重启服务（代码更新后）
cd /opt/dormitory_management
git pull origin master
source venv/bin/activate
python manage.py migrate
deactivate
sudo systemctl restart dormitory

# 查看错误日志
sudo journalctl -u dormitory --since "5 minutes ago"

# 重启 Nginx
sudo systemctl restart nginx
```

---

## 故障排查

| 问题 | 解决 |
|------|------|
| 访问不了 | 检查腾讯云安全组是否开放 80 端口 |
| 502 Bad Gateway | `sudo journalctl -u dormitory` 查看 Gunicorn 日志 |
| 静态文件不显示 | `python manage.py collectstatic` 重新收集 |
| 数据库错误 | 检查 `/opt/dormitory_management/db.sqlite3` 权限 |
