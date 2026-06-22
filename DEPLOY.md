# 🚀 学生宿舍管理系统 — 腾讯云部署完整教程

> 从零开始，手把手教你将网站部署到云端。
> **不管你是 Ubuntu 还是 CentOS，部署脚本自动适配。**

---

## 📖 目录

1. [购买云服务器](#一购买腾讯云服务器)
2. [连接服务器](#二连接你的服务器)
3. [配置安全组（开放端口）](#三配置安全组开放端口)
4. [一键部署（3条命令）](#四一键部署网站)
5. [验证网站是否上线](#五验证网站是否上线)
6. [日常维护](#六日常维护)
7. [常见问题排查](#七常见问题排查)

---

## 前置知识

你需要准备好：
- ✅ 本项目已上传至 GitHub：[L1nZzz166/dormitory-management-system](https://github.com/L1nZzz166/dormitory-management-system)
- ✅ 一个腾讯云账号（没有的话需要先去 [cloud.tencent.com](https://cloud.tencent.com) 注册）
- ✅ 一个域名（可选，有公网 IP 就够了）

**不需要懂 Linux，每一条命令都会解释清楚，跟着做就行。**

---

## 一、购买腾讯云服务器

### 1.1 选哪种服务器？

腾讯云有两大类：

| 类型 | 特点 | 推荐人群 |
|------|------|----------|
| **轻量应用服务器** | 便宜、界面简单、开箱即用 | 个人项目、学生首选 |
| **云服务器 CVM** | 功能更多、可定制性强 | 企业、需要复杂配置 |

> 💡 学生认证后轻量服务器最低 **¥28/月**，做一个展示网站完全够用。

### 1.2 购买步骤

1. 打开 [腾讯云轻量服务器购买页](https://buy.cloud.tencent.com/lighthouse)
2. 按下面选择：

| 配置项 | 推荐选择 |
|--------|----------|
| 地域 | 离自己最近的（广州/上海/北京） |
| 镜像 | **Ubuntu 22.04** 或 **CentOS 7.9** 都行 |
| 套餐 | 2核2G（最低配就够） |
| 时长 | 先买 1 个月试试 |

3. 点击「立即购买」并支付

> ⚠️ 不管是 Ubuntu 还是 CentOS，部署脚本都能自动适配，不用纠结选哪个。

### 1.3 购买后必须记录的信息

购买完成后，去控制台首页，你会看到你的服务器信息：

```
实例名称          状态      公网 IP        到期时间
xxxxxxxx          运行中    1.2.3.4        2026-07-22
```

**✏️ 记下「公网 IP」和「密码」，后面每一步都要用到。**

---

## 二、连接你的服务器

你现在需要从自己的电脑"远程登录"到云服务器。根据你用的操作系统选择对应方式：

---

### 🪟 Windows 系统

#### 方式一：PowerShell（推荐，Windows 自带）

1. 按键盘 `Win + R`，输入 `powershell`，回车
2. 在蓝色窗口中输入：

```bash
ssh root@你的公网IP
```

例如：
```bash
ssh root@1.2.3.4
```

3. 第一次连接会问：
```
Are you sure you want to continue connecting (yes/no)?
```
输入 `yes` 回车。

4. 输入密码（**注意：输入时屏幕不会有任何显示，这是正常的安全设计**），输完回车。

#### 方式二：腾讯云网页终端（最简单，啥也不用装）

1. 打开腾讯云控制台 → 轻量应用服务器
2. 点击你的服务器名称
3. 点击右上角「**登录**」按钮
4. 选择「**标准登录**」→ 输入密码即可

> 💡 网页终端不需要安装任何软件，但复制粘贴不太方便。长远使用建议 PowerShell。

---

### 🍎 Mac 系统

1. 打开「**终端**」应用（在启动台搜索 Terminal）
2. 输入：

```bash
ssh root@你的公网IP
```

3. 第一次连接输入 `yes`，然后输入密码

---

### 🐧 Linux 系统

打开终端，步骤同上。

---

### 登录成功的样子

```
Welcome to Ubuntu 22.04 LTS (GNU/Linux 5.15.0-xxx)
  System information as of ...

root@VM-xxxxx:~#
```

看到 `root@...:~#` 就说明登录成功了！后面所有命令都在这个黑窗口里输入。

---

## 三、配置安全组（开放端口）

> ⚠️ **这一步非常重要！不开放端口，网站从外网根本打不开。**

云服务器的端口默认是关闭的，你需要手动放行 HTTP 的 **80 端口**。

### 轻量应用服务器

1. 控制台 → 轻量应用服务器 → 点击你的实例
2. 点击顶部的「**防火墙**」标签页
3. 点击「**添加规则**」
4. 填写：

| 应用类型 | 端口 | 策略 |
|----------|------|------|
| HTTP(80) | 80 | 允许 |

5. 确认列表中出现了 `TCP:80` 这一条

### 云服务器 CVM

1. 控制台 → 云服务器 → 点击你的实例
2. 点击「**安全组**」标签页
3. 点击绑定的安全组名称，进入详情
4. 「**入站规则**」→「**添加规则**」：

| 类型 | 来源 | 协议端口 |
|------|------|----------|
| HTTP(80) | 0.0.0.0/0 | TCP:80 |

---

## 四、一键部署网站

现在回到你连接服务器那个黑窗口，按顺序执行以下命令。

---

### 第 1 步：下载项目

```bash
git clone https://github.com/L1nZzz166/dormitory-management-system.git
```

含义：从 GitHub 把项目代码下载到服务器。

> ❓ **如果提示 `git: command not found`**，说明服务器还没装 git。

根据你的系统执行对应的安装命令：

**如果你是 Ubuntu/Debian：**
```bash
apt-get update && apt-get install -y git
```

**如果你是 CentOS/TencentOS：**
```bash
yum install -y git
```

安装完 Git 后，重新执行 `git clone ...` 这条命令。

---

### 第 2 步：运行部署脚本

```bash
cd dormitory-management-system
bash deploy.sh --ip 你的公网IP
```

例如你的公网 IP 是 `1.2.3.4`：
```bash
bash deploy.sh --ip 1.2.3.4
```

> ❓ **如果你有域名**，把 `--ip` 换成 `--domain`：
> ```bash
> bash deploy.sh --domain www.你的域名.com
> ```

---

### 第 3 步：等待完成

脚本会自动执行以下所有操作，你只需要看着：

```
[INFO] 正在检测操作系统...
[INFO] 检测到 Debian/Ubuntu 系统，使用 apt-get 安装
[INFO] ========================================
[INFO]   学生宿舍管理系统 - 开始部署
[INFO]   系统: ubuntu | 服务器: 1.2.3.4
[INFO] ========================================
[INFO] [1/6] 更新并安装系统依赖...        ← 自动识别 apt 还是 yum
[INFO] [2/6] 克隆项目代码...
[INFO] [3/6] 创建 Python 虚拟环境并安装依赖...
[INFO] [4/6] 初始化数据库...
[INFO] [5/6] 配置 Nginx 反向代理...
[INFO] [6/6] 创建 systemd 服务...
[INFO]
[INFO] ========================================
[INFO]   ✅ 部署完成！
[INFO] ========================================
[INFO]   访问地址: http://1.2.3.4
[INFO]   系统类型: ubuntu
```

看到 **`✅ 部署完成！`** 就说明一切就绪。整个过程大约 3-5 分钟。

---

### 脚本自动做了什么？（不需要手操，看一眼就行）

| 步骤 | 说明 |
|------|------|
| 检测系统 | 自动识别 Ubuntu/CentOS/TencentOS，选对包管理器 |
| 安装依赖 | Python3、pip、Nginx、Git |
| 克隆代码 | 从 GitHub 拉取最新代码 |
| Python 环境 | 创建虚拟环境，安装 Django2.2 + Gunicorn |
| 数据库 | 建表 + 登录账号 + 演示数据 |
| Nginx | 配置反向代理，接管 80 端口 |
| systemd | 设置开机自启，挂了自动重启 |

---

### 部署中可能遇到的问题

| 报错 | 解决方法 |
|------|----------|
| `Permission denied` | 命令前加 `sudo`：`sudo bash deploy.sh --ip 1.2.3.4` |
| `Could not connect to github.com` | 服务器暂时连不上 GitHub，等几分钟重试；或者看 [7.6 手动上传方案](#76-github-连不上怎么办手动上传) |
| `port 80 is already in use` | 80 端口被占用：CentOS 停 `sudo systemctl stop httpd`，全部系统通用 `sudo systemctl stop apache2`，再重试 |

---

## 五、验证网站是否上线

### 5.1 打开浏览器

地址栏输入：

```
http://你的公网IP
```

比如 `http://1.2.3.4`

### 5.2 你应该看到

| 步骤 | 预期效果 |
|------|----------|
| 打开网址 | 紫色渐变的**登录页面** |
| 输入账号 | `24510206030229` |
| 输入密码 | `123456` |
| 登录成功 | 进入**学生宿舍管理系统首页** |

### 5.3 完整检查清单

- [ ] 登录页面能正常打开（不是连接超时）
- [ ] 输入账号密码能成功登录
- [ ] 首页三个功能卡片正常显示
- [ ] 学生管理页面能添加、编辑、删除学生
- [ ] 宿舍管理页面能查看入住情况
- [ ] 报修管理页面能提交和跟踪报修
- [ ] 页面样式美观（有颜色、有卡片、有图标——不是纯白文字堆砌）
- [ ] 页面底部显示「姓名：林志杰」「学号：29」
- [ ] 导航栏「退出」按钮能退出登录

### 5.4 有问题？

→ 直接翻到 [第七章常见问题排查](#七常见问题排查)

---

## 六、日常维护

### 代码更新后同步到服务器

在你自己的电脑上改完代码、push 到 GitHub 后：

```bash
# SSH 登录服务器
ssh root@你的公网IP

# 拉取最新代码并重启
cd /opt/dormitory_management
sudo git pull origin master
sudo systemctl restart dormitory
```

### 常用管理命令速查

```bash
# 查看服务是否运行（看到 active (running) 就正常）
sudo systemctl status dormitory

# 重启网站
sudo systemctl restart dormitory

# 查看最近 50 条日志（排查错误时用）
sudo journalctl -u dormitory -n 50

# 实时查看日志（看谁在访问你的网站）
sudo tail -f /var/log/nginx/dormitory_access.log
```

---

## 七、常见问题排查

### 7.1 浏览器访问显示「无法访问此网站」/「连接超时」

**可能原因：** 端口没开放、Nginx 没跑起来、或系统防火墙拦了。

**逐项排查：**

```bash
# ① Nginx 有没有在跑？
sudo systemctl status nginx
# 看到 inactive (dead) 就执行：
sudo systemctl start nginx

# ② 检查腾讯云安全组/防火墙
# 登录腾讯云网页控制台 → 你的服务器 → 防火墙/安全组
# 确认规则列表里有 TCP:80 → 没有就按第三章添加

# ③ CentOS 系统额外检查系统防火墙
sudo firewall-cmd --list-ports
# 如果 80 端口没在列表里：
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

---

### 7.2 访问后显示「502 Bad Gateway」

**原因：** Nginx 在跑，但 Gunicorn（网站的 Python 进程）挂了。

**解决：**

```bash
sudo systemctl restart dormitory
# 等 3 秒，然后检查状态：
sleep 3
sudo systemctl status dormitory
# 确认显示 active (running)
```

如果反复 502，查看 Gunicorn 日志找具体原因：

```bash
sudo journalctl -u dormitory --since "5 minutes ago"
```

---

### 7.3 CentOS 系统 Nginx 自检不通过

CentOS 上 Nginx 配置检测可能提示目录不存在：

```bash
# 创建日志目录
sudo mkdir -p /var/log/nginx
sudo touch /var/log/nginx/dormitory_access.log /var/log/nginx/dormitory_error.log

# 再测一次
sudo nginx -t
sudo systemctl start nginx
```

---

### 7.4 页面能打开但样式全乱了（纯白背景没颜色）

**原因：** 静态文件（CSS）没正确加载。

**解决：**

```bash
cd /opt/dormitory_management
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

然后**强制刷新浏览器**：按 `Ctrl + F5`（Windows）/ `Cmd + Shift + R`（Mac）。

---

### 7.5 服务器重启后网站打不开

确认服务设置了开机自启：

```bash
sudo systemctl is-enabled dormitory    # 应输出 enabled
sudo systemctl is-enabled nginx        # 应输出 enabled
```

如果输出 `disabled`，执行：

```bash
sudo systemctl enable dormitory
sudo systemctl enable nginx
```

---

### 7.6 GitHub 连不上怎么办？（手动上传）

如果服务器怎么也连不上 GitHub，可以**从你电脑直接把项目传到服务器**：

#### 在你自己的电脑上（Windows PowerShell）

**① 打包项目：**

```bash
cd E:/项目/dormitory_management
tar -czf dormitory.tar.gz --exclude=venv --exclude=db.sqlite3 --exclude=__pycache__ .
```

**② 上传到服务器：**

```bash
scp E:/项目/dormitory_management/dormitory.tar.gz root@你的公网IP:/opt/
```

#### 然后 SSH 回服务器

```bash
ssh root@你的公网IP
cd /opt
mkdir -p dormitory_management
tar -xzf dormitory.tar.gz -C dormitory_management
cd dormitory_management
python3 -m venv venv
source venv/bin/activate
pip install django==2.2.0 gunicorn -q
python manage.py migrate
python create_user.py
python seed_data.py
```

然后重新运行部署脚本（会自动跳过已存在的代码，只配置 Nginx 和服务）：

```bash
bash deploy.sh --ip 你的公网IP
```

---

### 7.7 CentOS 提示「sudo: command not found」

你当前就是 root 用户，去掉命令前面的 `sudo` 即可。

比如 `sudo systemctl start nginx` 改成 `systemctl start nginx`。

---

## 📞 还需要帮助？

- GitHub 仓库：[L1nZzz166/dormitory-management-system](https://github.com/L1nZzz166/dormitory-management-system)
- 有问题可以到仓库提交 Issue

---

> 🎉 完成以上所有步骤后，你的学生宿舍管理系统就成功上线了！
> 在任何一台联网的电脑上输入 `http://你的公网IP` 都能访问到你的网站。
