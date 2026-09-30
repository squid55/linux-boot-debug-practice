#!/bin/bash
# 2편과 같은 결과를 커널 패치 없이 얻기:
#   - 어떤 실행 파일이 실행됐나  → sched:sched_process_exec (기본 제공 트레이스포인트)
#   - 어떤 파일을 열었나        → vfs_open 에 kprobe 를 직접 붙임
# sudo 필요. 기본 5초 동안 기록한다.
set -e
[ "$EUID" -eq 0 ] || { echo "sudo 로 실행하세요"; exit 1; }
SEC="${1:-5}"
T=/sys/kernel/tracing; mountpoint -q $T || mount -t tracefs nodev $T
OUT="$(cd "$(dirname "$0")/.." && pwd)/out"; mkdir -p "$OUT"

cleanup() {
  echo 0 > $T/tracing_on 2>/dev/null || true
  echo 0 > $T/events/sched/sched_process_exec/enable 2>/dev/null || true
  echo 0 > $T/events/kprobes/vfsopen/enable 2>/dev/null || true
  echo '-:vfsopen' > $T/kprobe_events 2>/dev/null || true
}
trap cleanup EXIT

# 연 파일의 경로까지 같이 찍는다 (dentry 이름)
echo 'p:vfsopen vfs_open path=+0(+0(%di)):string' > $T/kprobe_events 2>/dev/null \
  || echo 'p:vfsopen vfs_open' > $T/kprobe_events
echo 1 > $T/events/kprobes/vfsopen/enable
echo 1 > $T/events/sched/sched_process_exec/enable
echo > $T/trace; echo 1 > $T/tracing_on

echo "${SEC}초 동안 기록합니다. 다른 터미널에서 ls, vi, cd 등을 실행해보세요."
sleep "$SEC"
echo 0 > $T/tracing_on

F="$OUT/userspace-$(date +%H%M%S).log"
cp $T/trace "$F"; chown "${SUDO_USER:-root}" "$F" 2>/dev/null || true
echo
echo "== 실행된 프로그램 (sched_process_exec)"
grep sched_process_exec "$F" | sed -E 's/.*filename=([^ ]+).*/  \1/' | sort | uniq -c | sort -rn | head -10
echo "== 열린 파일 (vfs_open)"
grep vfsopen "$F" | head -10
echo
echo "전체 로그: $F  ($(grep -vc '^#' "$F") 줄)"
