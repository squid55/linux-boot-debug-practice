#!/bin/bash
# uprobe: 사용자 공간 함수 호출을 커널 ftrace 로 추적한다 (sudo 필요)
set -e
[ "$EUID" -eq 0 ] || { echo "sudo 로 실행하세요"; exit 1; }
cd "$(dirname "$0")"
BIN="$PWD/target"; [ -x "$BIN" ] || make -s
T=/sys/kernel/tracing; mountpoint -q $T || mount -t tracefs nodev $T

# 바이너리 안에서 compute 심볼의 오프셋 구하기
OFF=$(nm -C "$BIN" | awk '$3=="compute"{print $1}')
[ -n "$OFF" ] || { echo "compute 심볼을 못 찾음"; exit 1; }
echo "compute 오프셋: 0x$OFF"

echo > $T/uprobe_events
echo "p:kea/compute $BIN:0x$OFF" > $T/uprobe_events
echo 1 > $T/events/kea/compute/enable
echo > $T/trace; echo 1 > $T/tracing_on

sudo -u "${SUDO_USER:-$USER}" "$BIN" 3 >/dev/null

echo 0 > $T/tracing_on
echo "== 추적 결과"
grep -v '^#' $T/trace | head -10
echo 0 > $T/events/kea/compute/enable; echo > $T/uprobe_events
