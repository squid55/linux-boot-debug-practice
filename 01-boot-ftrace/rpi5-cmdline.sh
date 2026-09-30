#!/bin/bash
# 라즈베리파이(5 포함)에서 커널 커맨드라인에 부팅 트레이싱 옵션을 넣고 뺀다.
# ★ 이 스크립트는 라즈베리파이 위에서 실행해야 한다 (PC 아님).
#
#   sudo ./rpi5-cmdline.sh show
#   sudo ./rpi5-cmdline.sh add initcall     # initcall + 모듈 로딩 추적
#   sudo ./rpi5-cmdline.sh add exec         # 실행 파일·파일 열기 추적
#   sudo ./rpi5-cmdline.sh remove
# 적용하려면 재부팅해야 한다.
set -e
F=/boot/firmware/cmdline.txt
[ -f "$F" ] || F=/boot/cmdline.txt
[ -f "$F" ] || { echo "cmdline.txt 를 못 찾음 — 라즈베리파이에서 실행하세요"; exit 1; }
[ "$EUID" -eq 0 ] || { echo "sudo 로 실행하세요"; exit 1; }

INITCALL='trace_buf_size=8M trace_event=initcall:*,module:module_load'
EXECTRACE='trace_buf_size=8M trace_event=sched:sched_process_exec,syscalls:sys_enter_openat'

show() { echo "[$F]"; cat "$F"; }

case "${1:-show}" in
  show) show ;;
  add)
    B="$F.bak-$(date +%Y%m%d-%H%M%S)"; cp "$F" "$B"; echo "백업: $B"
    case "${2:-initcall}" in
      initcall) ADD="$INITCALL" ;;
      exec)     ADD="$EXECTRACE" ;;
      *) echo "add initcall | add exec"; exit 1 ;;
    esac
    # cmdline.txt 는 반드시 한 줄이어야 한다. 기존 trace 옵션은 지우고 새로 붙인다.
    NEW=$(tr -d '\n' < "$F" | sed -E 's/ ?trace_buf_size=[^ ]*//g; s/ ?trace_event=[^ ]*//g')
    printf '%s %s\n' "$NEW" "$ADD" > "$F"
    echo; show; echo; echo "재부팅해야 적용됩니다: sudo reboot" ;;
  remove)
    B="$F.bak-$(date +%Y%m%d-%H%M%S)"; cp "$F" "$B"; echo "백업: $B"
    NEW=$(tr -d '\n' < "$F" | sed -E 's/ ?trace_buf_size=[^ ]*//g; s/ ?trace_event=[^ ]*//g')
    printf '%s\n' "$NEW" > "$F"; echo; show ;;
  *) echo "사용법: $0 [show|add initcall|add exec|remove]" ;;
esac
