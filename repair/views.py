from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Repair
from .forms import RepairForm


@login_required
def repair_list(request):
    """报修列表页面"""
    repairs = Repair.objects.all()
    return render(request, 'repair/list.html', {'repairs': repairs})


@login_required
def repair_add(request):
    """提交报修申请"""
    if request.method == 'POST':
        form = RepairForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('repair:list')
    else:
        form = RepairForm()
    return render(request, 'repair/add.html', {'form': form})


@login_required
def repair_detail(request, pk):
    """报修详情"""
    repair = get_object_or_404(Repair, pk=pk)
    return render(request, 'repair/detail.html', {'repair': repair})


@login_required
def repair_complete(request, pk):
    """标记报修为已完成"""
    import datetime
    repair = get_object_or_404(Repair, pk=pk)
    repair.status = 'completed'
    repair.complete_time = datetime.datetime.now()
    repair.save()
    return redirect('repair:list')
