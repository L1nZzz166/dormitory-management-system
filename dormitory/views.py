from django.shortcuts import render, redirect, get_object_or_404
from .models import Dormitory
from .forms import DormitoryForm
from student.models import Student


def dormitory_list(request):
    """宿舍列表页面"""
    dormitories = Dormitory.objects.all()
    return render(request, 'dormitory/list.html', {'dormitories': dormitories})


def dormitory_add(request):
    """添加宿舍"""
    if request.method == 'POST':
        form = DormitoryForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('dormitory:list')
    else:
        form = DormitoryForm()
    return render(request, 'dormitory/add.html', {'form': form})


def dormitory_detail(request, pk):
    """宿舍详情 - 显示该宿舍入住的学生"""
    dormitory = get_object_or_404(Dormitory, pk=pk)
    students = Student.objects.filter(dormitory=dormitory)
    return render(request, 'dormitory/detail.html', {
        'dormitory': dormitory,
        'students': students,
    })


def dormitory_delete(request, pk):
    """删除宿舍"""
    dormitory = get_object_or_404(Dormitory, pk=pk)
    dormitory.delete()
    return redirect('dormitory:list')
