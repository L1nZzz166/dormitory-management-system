from django.shortcuts import render, redirect, get_object_or_404
from .models import Student
from .forms import StudentForm


def student_list(request):
    """学生列表页面"""
    students = Student.objects.all()
    return render(request, 'student/list.html', {'students': students})


def student_add(request):
    """添加学生"""
    if request.method == 'POST':
        form = StudentForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('student:list')
    else:
        form = StudentForm()
    return render(request, 'student/add.html', {'form': form})


def student_edit(request, pk):
    """编辑学生信息"""
    student = get_object_or_404(Student, pk=pk)
    if request.method == 'POST':
        form = StudentForm(request.POST, instance=student)
        if form.is_valid():
            form.save()
            return redirect('student:list')
    else:
        form = StudentForm(instance=student)
    return render(request, 'student/edit.html', {'form': form, 'student': student})


def student_delete(request, pk):
    """删除学生"""
    student = get_object_or_404(Student, pk=pk)
    student.delete()
    return redirect('student:list')
