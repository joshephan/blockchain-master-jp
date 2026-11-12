# 一行に状態を変えうる式がいくつあるかを数える
# 数えたもの: 代入(=)、複合代入(+= など)、++、--、push、pop、delete、
#        同じファイルでview・pureなしで宣言された関数の呼び出し
# 除くもの: 宣言と同時に入れる最初の値の = (uint256 k = i; のような行)
import re, sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
src = "\n".join(l.split("//")[0] for l in lines)

writers = set()
for m in re.finditer(r"function\s+(\w+)\s*\(([^{;]*)", src):
    if not re.search(r"\b(view|pure)\b", m.group(2)):
        writers.add(m.group(1))

ops = re.compile(r"(\+\+|--|[-+*/%|&^]=|<<=|>>=|(?<![=!<>])=(?![=>])|\.push\(|\.pop\(|\bdelete\b)")
calls = re.compile(r"\b(" + "|".join(sorted(writers)) + r")\s*\(")
decl = re.compile(r"^\s*[\w.\[\]]+(\s+(public|private|internal|constant|immutable|memory|storage|calldata))*\s+\w+\s*=[^=]")

print("状態を変える関数:", ", ".join(sorted(writers)))
two = 0
for n, line in enumerate(lines, 1):
    code = line.split("//")[0]
    if re.search(r"\bfunction\b", code):
        continue
    k = len(ops.findall(code)) + len(calls.findall(code))
    if decl.match(code):
        k -= 1
    if k:
        print(f"{n:3} [{k}] {code.strip()}")
    if k >= 2:
        two += 1
print("2個以上の行:", two)
