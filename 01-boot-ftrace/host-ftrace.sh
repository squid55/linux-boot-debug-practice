#!/bin/bash
# 호스트에서 바로 해보는 ftrace 실습 (sudo 필요, 부팅 후 시점)
#   sudo ./host-ftrace.sh function 2     함수 트레이서 2초
#   sudo ./host-ftrace.sh event sched:sched_switch 2
set -e
[ "$EUID" -eq 0 ] || { echo "sudo 로 실행하세요"; exit 1; }
T=/sys/kernel/tracing
mountpoint -q $T || mount -t tracefs nodev $T
MODE="${1:-function}"; SEC="${3:-2}"
OUT="$(cd "$(dirname "$0")/.." && pwd)/out"; mkdir -p "$OUT"

echo nop > $T/current_tracer; echo > $T/trace; echo > $T/set_event
case "$MODE" in
  function) echo function > $T/current_tracer ;;
  graph)    echo function_graph > $T/current_tracer; echo "${2:-vfs_open}" > $T/set_graph_function ;;
  event)    echo "${2:-sched:sched_switch}" > $T/set_event ;;
esac
echo 1 > $T/tracing_on; sleep "$SEC"; echo 0 > $T/tracing_on

F="$OUT/host-$MODE-$(date +%H%M%S).txt"
cp $T/trace "$F"
echo nop > $T/current_tracer; echo > $T/set_event
echo "저장: $F  ($(wc -l < "$F") 줄)"
head -20 "$F"
