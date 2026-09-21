import sys, re
from collections import defaultdict

with open(sys.argv[1], "r", encoding="utf-8", errors="ignore") as fh:
    out = fh.read()
errs = []
for line in out.splitlines():
    m = re.search(r"Invalid constant value - (lib[^:]+):(\d+):(\d+)", line)
    if m:
        path = m.group(1).replace("\\", "/")
        errs.append((path, int(m.group(2))))

byfile = defaultdict(list)
for f, ln in errs:
    byfile[f].append(ln)

const_re = re.compile(r"\bconst\b")
for f, lns in byfile.items():
    with open(f, "r", encoding="utf-8") as fh:
        lines = fh.readlines()
    removed = set()
    for ln in sorted(set(lns)):
        idx = ln - 1
        for k in range(idx, max(-1, idx - 6), -1):
            if k in removed:
                break
            if const_re.search(lines[k]):
                lines[k] = re.sub(r"\bconst\s+", "", lines[k], count=1)
                removed.add(k)
                break
    with open(f, "w", encoding="utf-8") as fh:
        fh.writelines(lines)
    print("fixed", f, sorted(set(lns)))
