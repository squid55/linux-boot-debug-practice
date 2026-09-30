#!/bin/bash
# 게스트 안에서 실행: 부팅 중 쌓인 트레이스를 확인하고 파일로 저장한다.
T=/sys/kernel/tracing
[ -d $T ] || T=/sys/kernel/debug/tracing
echo "== 현재 트레이서: $(cat $T/current_tracer)"
echo "== 켜져 있는 이벤트:"; cat $T/set_event 2>/dev/null | head
echo "== 버퍼 크기: $(cat $T/buffer_size_kb) KB"
echo
echo "== 트레이스 앞부분 (30줄)"
head -30 $T/trace
echo
mkdir -p /mnt/out
F=/mnt/out/boot-trace-$(date +%H%M%S).txt
cp $T/trace "$F" && echo "저장: $F  ($(wc -l < "$F") 줄)"
