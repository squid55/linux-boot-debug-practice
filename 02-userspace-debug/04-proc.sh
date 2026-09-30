#!/bin/bash
# 실행 중인 프로세스를 /proc 으로 들여다보기
cd "$(dirname "$0")"; make -s
./target 20 >/dev/null & PID=$!
sleep 0.3
echo "PID=$PID"
echo "== 상태";        grep -E 'Name|State|VmRSS|Threads' /proc/$PID/status
echo "== 열린 파일";   ls -l /proc/$PID/fd 2>/dev/null | head
echo "== 메모리 맵 앞부분"; head -5 /proc/$PID/maps
echo "== 스택(커널)";  cat /proc/$PID/stack 2>/dev/null | head -5 || echo "  (권한 필요: sudo cat /proc/$PID/stack)"
wait $PID
