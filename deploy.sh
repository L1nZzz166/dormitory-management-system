#!/bin/bash
# ============================================
# 学生宿舍管理系统 - 腾讯云一键部署脚本
# 适用系统: Ubuntu 18.04 / 20.04 / 22.04
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/opt/dormitory_management"
DOMAIN_OR_IP=""   # 部署时通过命令行参数传入
GITHUB_REPO="https://github.com/L1nZzz166/dormitory-management-system.git"

echo_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --ip) DOMAIN_OR_IP="$2"; shift 2 ;;
        --domain) DOMAIN_OR_IP="$2"; shift 2 ;;
        -h|--help)
            echo "用法: bash deploy.sh --ip <你的服务器IP>"
            echo "     bash deploy.sh --domain <你的域名>"
            exit 0
            ;;
        *) echo_error "未知参数: $1"; exit 1 ;;
    esac
done

if [ -z "$DOMAIN_OR_IP" ]; then
    DOMAIN_OR_IP=$(curl -s ifconfig.me 2>/dev/null || echo "")
    if [ -z "$DOMAIN_OR_IP" ]; then
        echo_error "无法获取公网IP，请手动指定: bash deploy.sh --ip 1.2.3.4"
        exit 1
    fi
    echo_warn "自动检测到公网IP: $DOMAIN_OR_IP"
fi

echo_info "========================================"
echo_info "  学生宿舍管理系统 - 开始部署"
echo_info "  服务器: $DOMAIN_OR_IP"
echo_info "========================================"

# 1. 更新系统
echo_info "[1/8] 更新系统软件包..."
sudo apt-get update -qq

# 2. 安装必要软件
echo_info "[2/8] 安装 Python3、pip、nginx、git..."
sudo apt-get install -y -qq python3 python3-pip python3-venv nginx git

# 3. 创建项目目录
echo_info "[3/8] 创建项目目录..."
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

# 4. 克隆代码
echo_info "[4/8] 从 GitHub 克隆项目代码..."
if [ -d "$PROJECT_DIR/.git" ]; then
    cd $PROJECT_DIR && git pull origin master
else
    git clone $GITHUB_REPO $PROJECT_DIR
fi

# 5. 创建虚拟环境并安装依赖
echo_info "[5/8] 创建 Python 虚拟环境并安装依赖..."
cd $PROJECT_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q

# 6. 初始化数据库和种子数据
echo_info "[6/8] 初始化数据库..."
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# 创建登录账号
echo_info "创建默认登录账号（见 create_user.py）..."
python create_user.py

# 加载种子数据（如果数据库为空）
python seed_data.py

# 收集静态文件
echo_info "收集静态文件..."
python manage.py collectstatic --noinput 2>/dev/null || echo_warn "静态文件收集跳过（不影响运行）"

# 7. 配置 Nginx
echo_info "[7/8] 配置 Nginx 反向代理..."
sudo tee /etc/nginx/sites-available/dormitory > /dev/null << NGINX_END
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    # 日志
    access_log /var/log/nginx/dormitory_access.log;
    error_log /var/log/nginx/dormitory_error.log;

    # 静态文件
    location /static/ {
        alias $PROJECT_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # 代理到 Gunicorn
    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
    }

    # 文件上传大小限制
    client_max_body_size 10M;
}
NGINX_END

# 启用站点
sudo ln -sf /etc/nginx/sites-available/dormitory /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 测试 nginx 配置
sudo nginx -t

# 8. 创建 systemd 服务（让项目开机自启）
echo_info "[8/8] 创建 systemd 服务..."
sudo tee /etc/systemd/system/dormitory.service > /dev/null << SYSTEMD_END
[Unit]
Description=学生宿舍管理系统 Gunicorn Service
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
Environment="DJANGO_SETTINGS_MODULE=dormitory_management.settings"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn \\
    --workers 3 \\
    --bind 127.0.0.1:8001 \\
    --timeout 60 \\
    --access-logfile /var/log/dormitory_gunicorn.log \\
    --error-logfile /var/log/dormitory_gunicorn_error.log \\
    dormitory_management.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD_END

# 重启服务
sudo systemctl daemon-reload
sudo systemctl enable dormitory
sudo systemctl restart dormitory
sudo systemctl restart nginx

echo_info ""
echo_info "========================================"
echo_info "  ✅ 部署完成！"
echo_info "========================================"
echo_info "  访问地址: http://$DOMAIN_OR_IP"
echo_info "  登录账号信息见项目 create_user.py"
echo_info ""
echo_info "  管理命令:"
echo_info "    sudo systemctl status dormitory  # 查看服务状态"
echo_info "    sudo systemctl restart dormitory # 重启服务"
echo_info "    sudo journalctl -u dormitory -f  # 查看日志"
echo_info "========================================"
