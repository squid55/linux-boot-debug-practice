#!/bin/bash
# 실습에 필요한 조건이 갖춰졌는지 확인한다. (sudo 불필요)
ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
no(){ printf "  \033[31m✗\033[0m %s\n" "$1"; }

echo "[도구]"
for c in strace gdb perf qemu-system-x86_64 vng trace-cmd ltrace; do
  command -v "$c" >/dev/null && ok "$c" || no "$c  (없음)"
done

echo "[실행 중인 커널 설정]"
CFG=/boot/config-$(uname -r)
if [ -r "$CFG" ]; then
  for k in CONFIG_FTRACE CONFIG_FUNCTION_TRACER CONFIG_FUNCTION_GRAPH_TRACER \
           CONFIG_FTRACE_SYSCALLS CONFIG_KPROBE_EVENTS CONFIG_UPROBE_EVENTS; do
    grep -q "^$k=y" "$CFG" && ok "$k" || no "$k  (부팅 커널에 없음)"
  done
else
  no "$CFG 를 읽을 수 없음"
fi

echo "[tracefs]"
if [ -d /sys/kernel/tracing/events ]; then ok "/sys/kernel/tracing 사용 가능"
else no "/sys/kernel/tracing 미마운트 → sudo mount -t tracefs nodev /sys/kernel/tracing"; fi

echo "[커널 소스 (virtme-ng 실습용, 선택)]"
K="${KDIR:-$HOME/linux}"
[ -f "$K/arch/x86/boot/bzImage" ] && ok "빌드된 커널: $K" || no "빌드된 커널 없음 (KDIR 로 지정하거나 vng --build)"
