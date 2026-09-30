#!/bin/bash
# gdb 로 함수에 중단점 걸고 변수 보기 (배치 모드로 한 번 보여준 뒤, 대화형으로 진입)
cd "$(dirname "$0")"; make -s
echo "== 배치 실행: compute() 에서 멈추고 인자·반환값 확인"
gdb -q -batch \
    -ex 'break compute' -ex 'run 2' \
    -ex 'info args' -ex 'bt' -ex 'finish' -ex 'continue' \
    ./target 2>&1 | head -30
echo
echo "== 대화형으로 들어가려면:  gdb ./target   그다음  break compute / run 2 / next / print sum"
