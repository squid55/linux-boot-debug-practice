# 리눅스 부팅·유저스페이스 디버깅 실습 환경

부팅 과정과 유저스페이스 동작을 **ftrace / kprobe / uprobe** 로 들여다보는 실습 모음.
보드가 없어도 **virtme-ng** 로 커널을 띄워 같은 실습을 할 수 있고, 라즈베리파이에서는
커널 커맨드라인만 바꿔 부팅 시점부터 추적할 수 있다.

실습은 두 갈래다.

1. **부팅 시점 추적** — 어떤 `initcall` 이 오래 걸렸는지, 어떤 모듈이 언제 로딩됐는지
2. **유저스페이스 추적** — 어떤 프로그램이 실행되고 어떤 파일을 열었는지

## 필요한 것
- 리눅스 (Ubuntu 22.04 에서 확인)
- 커널에 `CONFIG_FTRACE`, `CONFIG_FUNCTION_TRACER`, `CONFIG_KPROBE_EVENTS`, `CONFIG_UPROBE_EVENTS`
- `strace`, `gdb`, (선택) `trace-cmd`, `ltrace`, `perf`
- virtme-ng 실습을 하려면: `qemu`, `vng`, 빌드된 커널 트리

```bash
./00-setup/check-env.sh      # 조건이 맞는지 먼저 확인
./00-setup/install-tools.sh  # 빠진 도구 설치 (sudo)
```

커널 트리 위치는 `KDIR` 로 지정한다. 기본값은 `~/linux`.
```bash
KDIR=~/linux-media/media-committers ./01-boot-ftrace/run-vng.sh initcall
```

## 폴더 구성

| 경로 | 내용 |
|---|---|
| `00-setup/` | 환경 점검, 도구 설치 |
| `01-boot-ftrace/` | 부팅 시점 추적 (virtme-ng / 라즈베리파이 / 호스트) |
| `02-userspace-debug/` | 실습 대상 프로그램과 strace · gdb · uprobe · kprobe 스크립트 |
| `out/` | 트레이스 결과 (git 에 올리지 않음) |
| `notes/` | 실습 기록 템플릿 |

## 1) 부팅 시점 ftrace  → `01-boot-ftrace/`
부팅 과정을 추적하려면 커널이 뜨기 전에 트레이서를 켜야 한다. 커널 cmdline 으로 지정한다.
실제 보드 대신 **virtme-ng 로 커널을 띄워서** 안전하게 연습한다.

```bash
./01-boot-ftrace/run-vng.sh initcall      # 영상 1편과 같은 설정 (initcall + 모듈 로딩)
./01-boot-ftrace/run-vng.sh exec          # 영상 2편과 같은 목적 (실행 파일·파일 열기)
./01-boot-ftrace/run-vng.sh events        # 주요 이벤트만 (가벼움)
./01-boot-ftrace/run-vng.sh function      # 함수 트레이서 (양이 많음)
./01-boot-ftrace/run-vng.sh graph vfs_open   # 특정 함수의 호출 그래프
./01-boot-ftrace/run-vng.sh printk        # 트레이스를 dmesg 로 흘림 (부팅 초반 확인)
```
게스트가 뜨면 안에서:
```bash
/mnt/out/../01-boot-ftrace/in-guest.sh    # 또는 아래 경로로 직접
bash ~/kea-debug-practice/01-boot-ftrace/in-guest.sh
```
결과는 `out/boot-trace-*.txt` 로 호스트에 남는다 (게스트에서 /mnt/out).

호스트에서 부팅 후 시점으로 연습하려면:
```bash
sudo ./01-boot-ftrace/host-ftrace.sh function 2
sudo ./01-boot-ftrace/host-ftrace.sh event sched:sched_switch 2
```

### 알아둘 커널 파라미터
| 파라미터 | 뜻 |
|---|---|
| `ftrace=function` | 부팅 초기부터 함수 트레이서 켜기 |
| `ftrace=function_graph` + `ftrace_graph_filter=<함수>` | 호출 그래프, 대상 함수 한정 |
| `trace_event=<subsys>:<event>` | 특정 트레이스포인트만 켜기 (쉼표로 여러 개) |
| `trace_buf_size=4M` | CPU당 링버퍼 크기 (기본값이 작아 초반이 덮인다) |
| `tp_printk` | 트레이스를 커널 로그로도 출력 (초반 디버깅용, 느려짐) |
| `trace_event=initcall:*` | 부팅 중 initcall 시작·종료를 기록 → 느린 초기화 함수 찾기 |
| `trace_event=sched:sched_process_exec` | 어떤 실행 파일이 실행됐는지 |
| `trace_event=syscalls:sys_enter_openat` | 어떤 파일을 열었는지 |

**cmdline 수정 규칙 (라즈베리파이):** `cmdline.txt` 는 **반드시 한 줄**이어야 하고,
옵션 사이는 **공백 하나**로 띄운다. 줄바꿈이 들어가면 그 뒤는 무시된다.
`rpi5-cmdline.sh` 가 이 규칙을 지키면서 기존 trace 옵션을 정리하고 백업을 남긴다.

### 부팅 시간 분석 흐름
```bash
# 1. 트레이싱을 켠 채로 부팅 (파이: cmdline 수정 후 재부팅 / PC: run-vng.sh initcall)
# 2. 부팅 후 트레이스 받기
./get-trace.sh
# 3. 오래 걸린 initcall 순위
./analyze-initcall.py ../out/ftrace-*.log 20
```
`analyze-initcall.py` 는 `initcall_start` 와 `initcall_finish` 의 시각 차이를 계산해
**오래 걸린 순으로 정렬**하고, 레벨 전환과 로딩된 모듈도 함께 요약한다.

## 2) userspace 동작 디버깅 → `02-userspace-debug/`
대상 프로그램 `target.c` 는 파일 쓰기, 메모리 할당, 계산 함수, 대기를 섞어 두었다.

```bash
cd 02-userspace-debug && make
./01-strace.sh      # 어떤 시스템 콜을 쓰는지 (요약 + 파일 관련만)
./02-gdb.sh         # compute() 에 중단점, 인자·백트레이스·반환값
./04-proc.sh        # 실행 중 /proc 으로 상태·열린 파일·메모리 맵 보기
sudo ./03-uprobe.sh # uprobe 로 사용자 함수 호출을 커널 ftrace 에 기록
sudo ./05-vfsopen-kprobe.sh 5   # 실행된 프로그램 + 열린 파일 (커널 패치 없이)
```

### 도구 고르는 기준
| 알고 싶은 것 | 도구 |
|---|---|
| 커널에 무엇을 요청하나 | `strace` |
| 라이브러리 함수 호출 | `ltrace` |
| 특정 지점에서 변수 값 | `gdb` |
| 운영 중인 프로그램을 멈추지 않고 추적 | `uprobe` (ftrace), `perf probe` |
| 커널 안에서 무슨 일이 일어나나 | ftrace, `trace-cmd` |
| 지금 상태 스냅샷 | `/proc/<pid>/` |

## 결과물
`out/` 에 트레이스와 로그가 쌓인다. 실습 메모는 `notes/` 에.

## 참고와 출처

이 저장소의 스크립트와 문서는 직접 작성한 것이다. 강의 자료나 영상 내용을 옮겨 담지 않았다.

실습 주제는 아래 공개 영상을 보고 따라 해보다가, 같은 내용을 내 환경에서 반복할 수 있도록
정리한 것이다. 영상 자체는 각 저작자의 것이므로 링크만 남긴다.

- Austin Kim, "KEA (part1): Boot-time ftrace 설정 및 실습" — https://www.youtube.com/watch?v=C79JWmxnWHo
- Austin Kim, "KEA (part2): userspace 동작 디버깅 실습" — https://www.youtube.com/watch?v=U5_5nR8OqME

영상 2편은 커널 패치를 적용해 실행 파일과 `vfs_open` 을 추적한다. 이 저장소에서는 패치 없이
기존 트레이스포인트(`sched:sched_process_exec`)와 `kprobe`(`vfs_open`)로 같은 정보를 얻는다.

### 더 읽을거리 (커널 문서)
- `Documentation/trace/ftrace.rst`
- `Documentation/trace/kprobetrace.rst`
- `Documentation/trace/uprobetracer.rst`
- `Documentation/admin-guide/kernel-parameters.txt` (`ftrace=`, `trace_event=`, `trace_buf_size=`, `tp_printk`)

## 라이선스
MIT — `LICENSE` 참고.
