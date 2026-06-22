from django.shortcuts import render


def index(request):
    """首页 - 学生宿舍管理系统主页"""
    context = {
        'name': '林志杰',
        'student_id': '29',
    }
    return render(request, 'home/index.html', context)
