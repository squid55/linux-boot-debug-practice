#!/bin/bash
# 부팅 시점부터 ftrace 를 켠 커널을 virtme-ng 로 띄운다.
#   ./run-vng.sh function          함수 트레이서
#   ./run-vng.sh events            주요 이벤트만 (가벼움)
#   ./run-vng.sh graph <함수이름>  함수 그래프 트레이서
# 종료는 게스트에서 Ctrl+D 또는 exit
set -e
# 커널 소스/빌드 디렉터리. 자신의 환경에 맞게 바꾸거나 KDIR 환경변수로 지정한다.
KDIR="${KDIR:-$HOME/linux}"
[ -d "$KDIR" ] || { echo "커널 디렉터리가 없습니다: $KDIR"; echo "KDIR=/path/to/linux $0 $*  형태로 지정하세요."; exit 1; }
OUT="$(cd "$(dirname "$0")/.." && pwd)/out"
MODE="${1:-events}"

case "$MODE" in
  function)
    APPEND="ftrace=function trace_buf_size=4M" ;;
  graph)
    FN="${2:-vfs_open}"
    APPEND="ftrace=function_graph ftrace_graph_filter=$FN trace_buf_size=4M" ;;
  events)
    APPEND="trace_event=sched:sched_switch,module:module_load trace_buf_size=2M" ;;
  initcall)
    # 부팅 중 initcall 하나하나와 모듈 로딩을 기록 (부팅 시간 분석용)
    APPEND="trace_event=initcall:*,module:module_load trace_buf_size=8M" ;;
  exec)
    # userspace 에서 무엇이 실행되고 어떤 파일을 여는지 (커널 패치 없이)
    APPEND="trace_event=sched:sched_process_exec,syscalls:sys_enter_openat trace_buf_size=8M" ;;
  printk)
    # 트레이스를 커널 로그(dmesg)로도 흘려보낸다 — 부팅 초반 확인용
    APPEND="trace_event=module:module_load tp_printk" ;;
  *) echo "모드: initcall | exec | function | graph <함수> | events | printk"; exit 1 ;;
esac

echo "커널: $KDIR"
echo "cmdline 추가: $APPEND"
echo "결과 저장 폴더(게스트에서 /mnt/out 으로 보임): $OUT"
echo
exec vng --run "$KDIR" --rwdir "$OUT:/mnt/out" --append "$APPEND"
