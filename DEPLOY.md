# 🚀 学生宿舍管理系统 — 腾讯云部署完整教程

> 从零开始，手把手教你将网站部署到云端，让任何人都能通过网址访问！

---

## 📖 教程目录

1. [购买云服务器](#一购买腾讯云服务器)
2. [连接到你的服务器](#二连接到你的服务器)
3. [配置安全组（开放端口）](#三配置安全组开放端口)
4. [一键部署网站](#四一键部署网站)
5. [验证网站是否上线](#五验证网站是否上线)
6. [日常维护](#六日常维护)
7. [常见问题排查](#七常见问题排查)

---

## 前置知识

在看这个教程之前，你已经有了：
- ✅ 一个 Django 网站项目（即本项目）
- ✅ 项目已上传到 GitHub
- ✅ 一个腾讯云账号（没有的话需要先注册）

本教程 **不需要你懂 Linux**，每一条命令都会解释清楚作用，跟着做就行。

---

## 一、购买腾讯云服务器

### 1.1 选择服务器类型

登录 [腾讯云控制台](https://console.cloud.tencent.com/)，搜索框输入"**轻量应用服务器**"。

> 💡 **为什么选轻量服务器？**
> - 价格便宜（学生价最低约 ¥28/月）
> - 预装系统镜像，开箱即用
> - 管理界面简单，适合个人项目

### 1.2 配置参数

| 配置项 | 推荐选择 |
|--------|----------|
| 地域 | 选离自己最近的（如上海、广州） |
| 镜像 | **Ubuntu 22.04 LTS** |
| 套餐 | CPU ≥ 2核，内存 ≥ 2GB（最低配就够用） |
| 时长 | 先买 1 个月试试，好用再续 |

### 1.3 购买后查看

购买成功后，进入控制台 → 轻量应用服务器，你会看到：

```
实例名称                   状态    公网IP        到期时间
我的服务器                 运行中   1.2.3.4      2026-07-22
```

**👉 记下「公网IP」，后面一直要用到。** 比如这里就是 `1.2.3.4`。

> ⚠️ 如果你买的是 **云服务器 CVM** 而不是轻量服务器，操作基本一样，只是界面略有不同。

---

## 二、连接到你的服务器

### 2.1 你用什么电脑？

#### 🪟 Windows 系统

**方法 A：使用 PowerShell（自带，推荐）**

按 `Win + R`，输入 `powershell`，回车。

在 PowerShell 窗口中输入：

```bash
ssh root@你的公网IP
```

示例：
```bash
ssh root@1.2.3.4
```

第一次连接会提示：
```
Are you sure you want to continue connecting (yes/no)?
```
输入 `yes` 然后回车。

**方法 B：使用腾讯云网页终端（最简单）**

打开腾讯云控制台 → 轻量应用服务器 → 点击你的服务器 → 点击右上角「登录」按钮 → 选择「标准登录」→ 输入密码即可。

> 💡 网页终端不需要安装任何软件，但复制粘贴不太方便。

---

#### 🍎 Mac 系统

打开「终端」应用（在启动台搜索 Terminal），输入：

```bash
ssh root@你的公网IP
```

第一次连接时输入 `yes`，然后输入密码。

---

#### 🐧 Linux 系统

打开终端，同上。

---

### 2.2 登录密码是什么？

1. 腾讯云控制台 → 轻量应用服务器 → 点击你的服务器
2. 页面右侧找「**密码**」或「**重置密码**」
3. 如果还没有密码，点击「重置密码」设置一个
4. SSH 登录时输入你设置的密码

> 💡 输入密码时屏幕**不会显示任何字符**（连 `***` 都不显示），这是安全设计。输完直接回车就行。

### 2.3 登录成功后

你会看到类似这样的欢迎信息：

```
Welcome to Ubuntu 22.04 LTS
root@VM-xxxxx:~#
```

看到 `root@...:~#` 就说明登录成功了！后面的命令都是在这个黑窗口里输入。

---

## 三、配置安全组（开放端口）

> 如果不做这一步，你的网站**从外面是打不开的**。就像家门没开，别人进不来。

### 3.1 腾讯云轻量服务器

1. 控制台 → 轻量应用服务器 → 点击你的服务器
2. 点击「**防火墙**」标签
3. 点击「**添加规则**」
4. 按下面填写：

| 项目 | 值 |
|------|-----|
| 应用类型 | HTTP(80) |
| 协议 | TCP |
| 端口 | 80 |
| 策略 | 允许 |

> ✅ 确保规则列表里有 `TCP:80` 这一条。

### 3.2 腾讯云 CVM（云服务器）

1. 控制台 → 云服务器 → 点击你的实例
2. 点击「**安全组**」标签
3. 点击绑定的安全组名称 → 进入安全组详情
4. 点击「**添加规则**」→ **入站规则**：

| 项目 | 值 |
|------|-----|
| 类型 | HTTP(80) |
| 来源 | 0.0.0.0/0 |
| 协议端口 | TCP:80 |
| 策略 | 允许 |

---

## 四、一键部署网站

在连接上服务器之后，依次执行以下命令。

### 4.1 克隆项目代码

```bash
git clone https://github.com/L1nZzz166/dormitory-management-system.git
```

> 这条命令会把 GitHub 上的项目代码下载到服务器。

如果提示 `git: command not found`，先执行：
```bash
apt-get update && apt-get install -y git
```

### 4.2 进入项目并运行部署脚本

```bash
cd dormitory-management-system
chmod +x deploy.sh
bash deploy.sh --ip 你的公网IP
```

示例：
```bash
bash deploy.sh --ip 1.2.3.4
```

### 4.3 部署过程

脚本会自动执行以下操作（大约需要 3-5 分钟）：

```
[INFO] ========================================
[INFO]   学生宿舍管理系统 - 开始部署
[INFO]   服务器: 1.2.3.4
[INFO] ========================================
[INFO] [1/8] 更新系统软件包...
[INFO] [2/8] 安装 Python3、pip、nginx、git...
[INFO] [3/8] 创建项目目录...
[INFO] [4/8] 从 GitHub 克隆项目代码...
[INFO] [5/8] 创建 Python 虚拟环境并安装依赖...
[INFO] [6/8] 初始化数据库...
[INFO] [7/8] 配置 Nginx 反向代理...
[INFO] [8/8] 创建 systemd 服务...
[INFO]
[INFO] ========================================
[INFO]   ✅ 部署完成！
[INFO] ========================================
```

看到 `✅ 部署完成！` 就说明一切顺利。

### 4.4 如果部署脚本中途报错

常见问题及解决：

| 报错 | 解决方法 |
|------|----------|
| `Permission denied` | 在命令前加 `sudo`，如 `sudo bash deploy.sh --ip 1.2.3.4` |
| `git: command not found` | `apt-get install -y git` |
| `Could not connect to github.com` | 服务器暂时连不上 GitHub，多试几次，或者手动上传项目 |
| `port 80 is already in use` | `sudo systemctl stop apache2` 然后重试 |

---

## 五、验证网站是否上线

### 5.1 浏览器访问

打开浏览器，地址栏输入：

```
http://你的公网IP
```

比如 `http://1.2.3.4`

### 5.2 你应该看到

✅ 首先看到 **登录页面**（紫色渐变背景）  
✅ 输入账号 `24510206030229`，密码 `123456`  
✅ 登录后看到学生宿舍管理系统首页  

### 5.3 检查清单

- [ ] 登录页面能正常打开
- [ ] 登录后首页显示正常
- [ ] 学生管理、宿舍管理、报修管理各页面能正常跳转
- [ ] 页面样式正常（有颜色、有布局，不是纯白文字）
- [ ] 页脚显示"林志杰，学号29"

### 5.4 如果打不开

参见 [常见问题排查](#七常见问题排查)。

---

## 六、日常维护

### 代码更新后如何同步到服务器？

当你修改了本地代码并 push 到 GitHub 后，SSH 登录服务器执行：

```bash
cd /opt/dormitory_management
sudo git pull origin master
sudo systemctl restart dormitory
```

### 常用管理命令

```bash
# 查看网站服务是否在运行
sudo systemctl status dormitory
# 看到 active (running) 就是正常运行中
# 按 q 退出查看

# 重启网站服务
sudo systemctl restart dormitory

# 查看网站运行日志（排错时用）
sudo journalctl -u dormitory -n 50

# 查看 Nginx 访问日志
sudo tail -f /var/log/nginx/dormitory_access.log
```

---

## 七、常见问题排查

### 7.1 浏览器访问显示"无法访问此网站"

**原因：** 端口没开放、Nginx 没启动、或防火墙拦截。

**排查步骤：**

```bash
# 第1步：检查 Nginx 是否运行
sudo systemctl status nginx
# 如果不是 active (running)，执行：
sudo systemctl start nginx

# 第2步：检查安全组是否开放 80 端口
# 回到腾讯云网页控制台检查 → 确认防火墙规则有 TCP:80
```

### 7.2 访问后显示 502 Bad Gateway

**原因：** Nginx 在运行，但 Gunicorn（Django 服务）没有启动。

**解决方法：**

```bash
sudo systemctl restart dormitory
sudo systemctl status dormitory   # 确认状态为 active (running)
```

### 7.3 页面能打开但样式错乱

**原因：** 静态文件没有被正确收集。

**解决方法：**

```bash
cd /opt/dormitory_management
source venv/bin/activate
python manage.py collectstatic --noinput
sudo systemctl restart nginx
```

### 7.4 登录后页面报错

```bash
# 查看详细错误日志
sudo journalctl -u dormitory --since "5 minutes ago"

# 常见原因：数据库未迁移
cd /opt/dormitory_management
source venv/bin/activate
python manage.py migrate
sudo systemctl restart dormitory
```

### 7.5 服务器重启后网站打不开

```bash
# 确认服务是否随系统启动
sudo systemctl is-enabled dormitory   # 应该输出 enabled
sudo systemctl is-enabled nginx        # 应该输出 enabled

# 如果没有自启，设置开机自启
sudo systemctl enable dormitory
sudo systemctl enable nginx
```

### 7.6 GitHub 连不上怎么办？

如果服务器无法访问 GitHub，可以手动上传项目：

**在你自己电脑上（Windows）：**

```bash
# 打包项目（排除 venv 和数据库）
cd E:/项目/dormitory_management
tar -czf dormitory.tar.gz --exclude=venv --exclude=db.sqlite3 --exclude=__pycache__ .
```

**上传到服务器（Windows PowerShell）：**

```bash
scp E:/项目/dormitory/dormitory.tar.gz root@你的公网IP:/opt/
```

**然后 SSH 登录服务器解压：**

```bash
cd /opt
mkdir -p dormitory_management
tar -xzf dormitory.tar.gz -C dormitory_management
cd dormitory_management
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python create_user.py
python seed_data.py
```

然后继续 [第四步中的 Nginx 配置](#33-配置-nginx) 和 [systemd 配置](#34-配置-systemd-服务)。

---

## 📞 还需要帮助？

项目 GitHub 仓库：https://github.com/L1nZzz166/dormitory-management-system

常见问题可以到仓库提交 Issue。

---

> 🎉 **恭喜！** 完成以上所有步骤后，你的网站就成功上线了！任何人都可以通过你服务器的公网 IP 访问你的学生宿舍管理系统。
