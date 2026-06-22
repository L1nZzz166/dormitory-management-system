"""创建默认登录账号"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dormitory_management.settings')
django.setup()

from django.contrib.auth.models import User

username = '24510206030229'
password = '123456'

if User.objects.filter(username=username).exists():
    user = User.objects.get(username=username)
    user.set_password(password)
    user.save()
    print(f'用户 {username} 已存在，密码已更新。')
else:
    User.objects.create_user(username=username, password=password)
    print(f'用户 {username} 创建成功！')

print(f'账号: {username}')
print(f'密码: {password}')
