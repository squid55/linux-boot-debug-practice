#!/bin/bash
# 지금까지 쌓인 ftrace 버퍼를 파일로 받아둔다. 게스트·호스트 어디서나 동작.
T=/sys/kernel/tracing; [ -d $T ] || T=/sys/kernel/debug/tracing
OUT="${1:-}"
if [ -z "$OUT" ]; then
  [ -d /mnt/out ] && OUT=/mnt/out || OUT="$(cd "$(dirname "$0")/.." && pwd)/out"
fi
mkdir -p "$OUT"
F="$OUT/ftrace-$(date +%m%d-%H%M%S).log"
cp "$T/trace" "$F"
echo "저장: $F  ($(grep -vc '^#' "$F") 줄)"
echo "현재 트레이서: $(cat $T/current_tracer) / 버퍼: $(cat $T/buffer_size_kb) KB"
