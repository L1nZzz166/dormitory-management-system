from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required


def user_login(request):
    """登录页面"""
    error_msg = ''
    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '').strip()
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            next_url = request.GET.get('next', '/')
            return redirect(next_url)
        else:
            error_msg = '账号或密码错误，请重新输入！'
    return render(request, 'home/login.html', {'error_msg': error_msg})


def user_logout(request):
    """退出登录"""
    logout(request)
    return redirect('home:login')


@login_required
def index(request):
    """首页 - 学生宿舍管理系统主页"""
    context = {
        'name': '林志杰',
        'student_id': '29',
    }
    return render(request, 'home/index.html', context)
