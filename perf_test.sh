#!/bin/bash
set -e

MODE="${1:-tuned}"  # 默认 tuned；传 "raw" 表示调优前
LOGFILE="perf_metrics_${MODE}.log"
> "$LOGFILE"

echo "[*] 运行模式: $MODE (调优前 = raw, 调优后 = tuned)"

# --- 自动识别磁盘 ---
DISK=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1; exit}' | head -n1)
[ -z "$DISK" ] && DISK="sda"
SCHEDULER_PATH="/sys/block/$DISK/queue/scheduler"

# --- 仅当 mode != raw 时才调优 ---
if [ "$MODE" = "tuned" ]; then
    echo "[*] 应用系统调优..."
    sudo sysctl -w vm.swappiness=1 kernel.shmall=268435456 kernel.shmmax=268435456 >/dev/null 2>&1 || true
    echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled >/dev/null 2>&1 || true
    if [ -w "$SCHEDULER_PATH" ]; then
        echo 'deadline' | sudo tee "$SCHEDULER_PATH" >/dev/null
    fi
else
    echo "[*] 保持系统默认配置（调优前）..."
fi

# --- 安装 numpy（如果尚未安装）---
if ! python3 -c "import numpy" >/dev/null 2>&1; then
    echo "[*] 安装 numpy..."
    pip3 install --quiet --no-cache-dir numpy
fi

# --- 矩阵乘法测试 ---
cat > matmul_test.py << 'PY'
import numpy as np, time, os
# 锁定单核以减少调度抖动（对公平比较很重要）
os.sched_setaffinity(0, {0})
a = np.random.randn(8000, 8000).astype(np.float32)
b = np.random.randn(8000, 8000).astype(np.float32)
start = time.perf_counter()
c = np.dot(a, b)
elapsed = time.perf_counter() - start
print(f"{elapsed:.1f}")
PY

# --- 执行计算 ---
echo "[*] 运行矩阵乘法测试..."
ELAPSED=$(timeout 180 python3 matmul_test.py 2>/dev/null || echo "超时")

# --- 同步采集 vmstat（与计算并行会干扰，所以先算完再采样）---
# 更准确的做法：在计算期间采样。但为简化，我们单独采样系统空闲态 + 计算态混合
# 实际建议：在后台启动 vmstat，前台跑计算
echo "[*] 采集系统指标（10秒，与计算同步）..."

# 启动 vmstat 后台采样
timeout 12 vmstat 1 11 > vmstat.log 2>/dev/null &
VMSTAT_PID=$!

# 立即运行计算（确保重叠）
COMPUTE_START=$(date +%s.%N)
python3 matmul_test.py >/dev/null 2>&1
COMPUTE_END=$(date +%s.%N)
COMPUTE_ELAPSED=$(echo "$COMPUTE_END - $COMPUTE_START" | bc -l)

# 等待 vmstat 结束
wait $VMSTAT_PID 2>/dev/null || true

# --- 解析指标（只取中间10行，排除首尾）---
PF=$(awk 'NR>2 && NR<=12 {sum+=$10} END {if(NR>2) print int(sum/10); else print 0}' vmstat.log)
WAIT=$(awk 'NR>2 && NR<=12 {sum+=$16} END {if(NR>2) printf "%.1f\n", sum/10; else print 0.0}' vmstat.log)
CPU_USER=$(awk 'NR>2 && NR<=12 {sum+=$13} END {if(NR>2) print int(sum/10); else print 0}' vmstat.log)

# 使用实际计算耗时（更准）
ELAPSED=$(printf "%.1f" $(echo "$COMPUTE_ELAPSED" | xargs printf "%.1f"))

# --- 输出 ---
echo
echo "=== 表4-2 数据（$MODE）==="
echo "指标,值"
echo "计算耗时（秒）,$ELAPSED"
echo "Page faults/s,$PF"
echo "I/O wait (%),$WAIT"
echo "CPU 用户态占比,$CPU_USER%"

{
    echo "计算耗时（秒）,$ELAPSED"
    echo "Page faults/s,$PF"
    echo "I/O wait (%),$WAIT"
    echo "CPU 用户态占比,$CPU_USER"
} >> "$LOGFILE"

echo
echo "数据已保存至: $(pwd)/$LOGFILE"