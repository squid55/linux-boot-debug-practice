#!/bin/bash
# 실습에 필요한데 아직 없는 도구들 (sudo 필요)
set -e
sudo apt update
sudo apt install -y trace-cmd ltrace linux-tools-common linux-tools-$(uname -r)
# bpftrace 는 선택 (용량 큼)
echo
echo "설치 확인:"
for c in trace-cmd ltrace perf strace gdb; do printf "  %-12s %s\n" "$c" "$(command -v $c || echo 없음)"; done
