#!/bin/bash
# ============================================
# 学生宿舍管理系统 - Linux 通用一键部署脚本
# 支持: Ubuntu/Debian | CentOS/RHEL/AlmaLinux/Rocky
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
echo_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_DIR="/opt/dormitory_management"
DOMAIN_OR_IP=""
GITHUB_REPO="https://github.com/L1nZzz166/dormitory-management-system.git"

# ============================================
# 1. 检测操作系统
# ============================================
echo_info "正在检测操作系统..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
else
    echo_error "无法检测操作系统版本"
    exit 1
fi

case "$OS_ID" in
    ubuntu|debian)
        PKG_MGR="apt-get"
        PKG_INSTALL="apt-get install -y -qq"
        PYTHON_PKG="python3"
        PYTHON_VENV_PKG="python3-venv"
        NGINX_SITES_DIR="/etc/nginx/sites-available"
        NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
        WEB_GROUP="www-data"
        echo_info "检测到 Debian/Ubuntu 系统，使用 apt-get 安装"
        ;;
    centos|rhel|almalinux|rocky|fedora|tencentos|anolis|openEuler)
        PKG_MGR="yum"
        PKG_INSTALL="yum install -y -q"
        PYTHON_PKG="python3"
        PYTHON_VENV_PKG="python3"
        NGINX_CONF_DIR="/etc/nginx/conf.d"
        WEB_GROUP="nginx"
        echo_info "检测到 CentOS/RHEL 系统，使用 yum 安装"
        ;;
    *)
        echo_error "不支持的操作系统: $OS_ID"
        echo_warn "此脚本支持 Ubuntu/Debian/CentOS/RHEL/AlmaLinux/Rocky"
        exit 1
        ;;
esac

# ============================================
# 2. 解析命令行参数
# ============================================
while [[ $# -gt 0 ]]; do
    case $1 in
        --ip) DOMAIN_OR_IP="$2"; shift 2 ;;
        --domain) DOMAIN_OR_IP="$2"; shift 2 ;;
        -h|--help)
            echo "用法: bash deploy.sh --ip <你的服务器IP>"
            echo "     bash deploy.sh --domain <你的域名>"
            exit 0 ;;
        *) echo_error "未知参数: $1"; exit 1 ;;
    esac
done

if [ -z "$DOMAIN_OR_IP" ]; then
    DOMAIN_OR_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "")
    if [ -z "$DOMAIN_OR_IP" ]; then
        echo_error "无法获取公网IP，请手动指定: bash deploy.sh --ip 1.2.3.4"
        exit 1
    fi
    echo_warn "自动检测到公网IP: $DOMAIN_OR_IP"
fi

echo_info "========================================"
echo_info "  学生宿舍管理系统 - 开始部署"
echo_info "  系统: $OS_ID | 服务器: $DOMAIN_OR_IP"
echo_info "========================================"

# ============================================
# 3. 安装系统依赖
# ============================================
echo_info "[1/6] 更新并安装系统依赖..."

if [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "rhel" ]; then
    # CentOS 7 需要 EPEL 源才能装 nginx
    sudo yum install -y -q epel-release 2>/dev/null || true
fi

sudo $PKG_MGR update -y -q 2>/dev/null || true
sudo $PKG_INSTALL $PYTHON_PKG $PYTHON_VENV_PKG nginx git 2>&1 | tail -5

# CentOS: 确保 python3-pip 和 python3-devel 也装上
if [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "rhel" ]; then
    sudo yum install -y -q python3-pip python3-devel gcc 2>/dev/null || true
fi

# ============================================
# 4. 创建目录并克隆代码
# ============================================
echo_info "[2/6] 克隆项目代码..."
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

if [ -d "$PROJECT_DIR/.git" ]; then
    cd $PROJECT_DIR && git pull origin master
else
    git clone $GITHUB_REPO $PROJECT_DIR
fi

# ============================================
# 5. Python 虚拟环境 + 依赖
# ============================================
echo_info "[3/6] 创建 Python 虚拟环境并安装依赖..."
cd $PROJECT_DIR
python3 -m venv venv 2>/dev/null || virtualenv venv 2>/dev/null || {
    echo_warn "创建虚拟环境失败，使用系统 Python"
    # 如果 venv 不可用（部分 CentOS），直接用系统 Python
    sudo pip3 install -r requirements.txt -q 2>/dev/null || \
    sudo pip3 install django==2.2.0 gunicorn pytz sqlparse -q
    VENV_ACTIVE=false
}
if [ "${VENV_ACTIVE}" != "false" ]; then
    source venv/bin/activate
    pip install --upgrade pip -q 2>/dev/null || true
    pip install -r requirements.txt -q
    VENV_ACTIVE=true
fi

# ============================================
# 6. 初始化数据库
# ============================================
echo_info "[4/6] 初始化数据库..."
python manage.py makemigrations --noinput
python manage.py migrate --noinput
python create_user.py
python seed_data.py

echo_info "收集静态文件..."
python manage.py collectstatic --noinput 2>/dev/null || echo_warn "静态文件收集跳过"

# ============================================
# 7. 配置 Nginx（适配 Ubuntu 和 CentOS）
# ============================================
echo_info "[5/6] 配置 Nginx 反向代理..."

if [ "$OS_ID" = "centos" ] || [ "$OS_ID" = "rhel" ]; then
    # CentOS: Nginx 用 conf.d 目录
    sudo mkdir -p /etc/nginx/conf.d
    sudo tee /etc/nginx/conf.d/dormitory.conf > /dev/null << NGINX_END
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    access_log /var/log/nginx/dormitory_access.log;
    error_log /var/log/nginx/dormitory_error.log;

    location /static/ {
        alias $PROJECT_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
    }

    client_max_body_size 10M;
}
NGINX_END

    # 屏蔽默认 server
    if [ -f /etc/nginx/nginx.conf ]; then
        sudo sed -i 's/^    server {/    #server {/' /etc/nginx/nginx.conf 2>/dev/null || true
    fi

    # CentOS SELinux: 允许 Nginx 代理
    sudo setsebool -P httpd_can_network_connect 1 2>/dev/null || true
else
    # Ubuntu/Debian: 标准 sites-available 目录
    sudo tee /etc/nginx/sites-available/dormitory > /dev/null << NGINX_END
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    access_log /var/log/nginx/dormitory_access.log;
    error_log /var/log/nginx/dormitory_error.log;

    location /static/ {
        alias $PROJECT_DIR/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
    }

    client_max_body_size 10M;
}
NGINX_END

    sudo ln -sf /etc/nginx/sites-available/dormitory /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
fi

sudo nginx -t && echo_info "Nginx 配置通过" || echo_error "Nginx 配置有误"

# ============================================
# 8. 创建 systemd 服务
# ============================================
echo_info "[6/6] 创建 systemd 服务..."

GUNICORN_BIN="$PROJECT_DIR/venv/bin/gunicorn"
if [ ! -f "$GUNICORN_BIN" ]; then
    GUNICORN_BIN=$(which gunicorn 2>/dev/null || echo "/usr/local/bin/gunicorn")
fi

sudo tee /etc/systemd/system/dormitory.service > /dev/null << SYSTEMD_END
[Unit]
Description=学生宿舍管理系统 Gunicorn
After=network.target

[Service]
User=$USER
Group=$WEB_GROUP
WorkingDirectory=$PROJECT_DIR
ExecStart=$GUNICORN_BIN \\
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

# ============================================
# 9. 启动服务
# ============================================
sudo systemctl daemon-reload
sudo systemctl enable dormitory
sudo systemctl enable nginx
sudo systemctl restart dormitory
sudo systemctl restart nginx

# ============================================
# 完成
# ============================================
echo_info ""
echo_info "========================================"
echo_info "  ✅ 部署完成！"
echo_info "========================================"
echo_info "  访问地址: http://$DOMAIN_OR_IP"
echo_info "  系统类型: $OS_ID"
echo_info ""
echo_info "  管理命令:"
echo_info "    sudo systemctl status dormitory  # 查看服务状态"
echo_info "    sudo systemctl restart dormitory # 重启网站"
echo_info "    sudo journalctl -u dormitory -f  # 实时日志"
echo_info "========================================"
