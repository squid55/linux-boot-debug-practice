#!/bin/bash
# 시스템 콜 추적: 프로그램이 커널에 무엇을 요청하는지 본다.
cd "$(dirname "$0")"; make -s
OUT="$(cd "$(dirname "$0")/.." && pwd)/out/strace-$(date +%H%M%S).txt"
echo "== 전체 시스템 콜 (요약)"
strace -c ./target 3 2>&1 | tail -20
echo
echo "== 파일 관련 시스템 콜만"
strace -f -e trace=openat,write,close -o "$OUT" ./target 2 >/dev/null
grep -E 'openat|write' "$OUT" | head -15
echo "전체 로그: $OUT"
