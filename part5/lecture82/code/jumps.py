# debug_traceCallの結果からpc、op、depth、スタックの上から二つの欄だけを取り出す
import json, sys
logs = json.load(open(sys.argv[1]))["structLogs"]
keep = {"JUMP", "JUMPDEST", "CALLER", "STATICCALL", "RETURN"}
for i, x in enumerate(logs):
    if int(sys.argv[2]) <= i <= int(sys.argv[3]) and x["op"] in keep:
        top = [hex(int(s, 16)) for s in x.get("stack", [])][-2:]
        print(f'{x["pc"]:>5} {x["op"]:<10} depth {x["depth"]}  {" ".join(top)}')
