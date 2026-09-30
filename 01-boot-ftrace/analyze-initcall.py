#!/usr/bin/env python3
"""부팅 ftrace 로그에서 initcall 실행 시간을 계산해 오래 걸린 순으로 보여준다.

사용법:  ./analyze-initcall.py ../out/ftrace-0930-200000.log [상위개수]

initcall:initcall_start 와 initcall:initcall_finish 이벤트의 타임스탬프 차이를 쓴다.
module:module_load 가 있으면 함께 요약한다.
"""
import re, sys, collections

path = sys.argv[1] if len(sys.argv) > 1 else sys.exit("로그 파일을 지정하세요")
topn = int(sys.argv[2]) if len(sys.argv) > 2 else 20

# 예: "  swapper/0-1  [000] d..1   1.234567: initcall_start: func=foo+0x0/0x40"
line_re = re.compile(r'\s+([\d.]+):\s+initcall_(start|finish|level):\s+(.*)')
func_re = re.compile(r'func=([^\s+]+)')

start, done, levels, modules = {}, [], [], []
for ln in open(path, errors='ignore'):
    if 'module_load' in ln:
        m = re.search(r'module_load:\s+(\S+)', ln)
        if m: modules.append(m.group(1))
    m = line_re.search(ln)
    if not m: continue
    ts, kind, rest = float(m.group(1)), m.group(2), m.group(3)
    if kind == 'level':
        levels.append((ts, rest.strip())); continue
    f = func_re.search(rest)
    if not f: continue
    name = f.group(1)
    if kind == 'start':
        start[name] = ts
    elif name in start:
        done.append((ts - start.pop(name), name, ts))

if not done:
    sys.exit("initcall 이벤트를 못 찾았습니다. trace_event=initcall:* 로 부팅했는지 확인하세요.")

total = sum(d for d, _, _ in done)
print(f"initcall {len(done)}개, 합계 {total*1000:.1f} ms\n")
print(f"{'순위':>3} {'소요(ms)':>10}  {'끝난 시각(s)':>12}  함수")
for i, (d, name, ts) in enumerate(sorted(done, reverse=True)[:topn], 1):
    print(f"{i:>3} {d*1000:>10.3f}  {ts:>12.6f}  {name}")

if levels:
    print(f"\n레벨 전환 {len(levels)}회 — 처음 5개: " + ", ".join(f"{t:.3f}s {l}" for t, l in levels[:5]))
if modules:
    c = collections.Counter(modules)
    print(f"\n로딩된 모듈 {len(modules)}개 (앞 15개): " + ", ".join(list(c)[:15]))
