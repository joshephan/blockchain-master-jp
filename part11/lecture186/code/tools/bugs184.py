import json, sys, pathlib
docs = pathlib.Path(sys.argv[1])
bugs = {b["name"]: b for b in json.loads((docs / "bugs.json").read_text(encoding="utf-8"))}
byv = json.loads((docs / "bugs_by_version.json").read_text(encoding="utf-8"))
EVM = ["homestead","tangerineWhistle","spuriousDragon","byzantium","constantinople","petersburg","istanbul","berlin","london","paris","shanghai","cancun","prague","osaka"]
mine = {"optimizer": True, "viaIR": True, "evmVersion": "osaka", "yulOptimizer": True, "ABIEncoderV2": True}
def evm_ok(cond, v):
    for op in (">=", "<=", ">", "<", "="):
        if cond.startswith(op):
            a, b = EVM.index(v), EVM.index(cond[len(op):])
            return {">=": a >= b, "<=": a <= b, ">": a > b, "<": a < b, "=": a == b}[op]
    return cond == v
print("bugs.jsonの項目", len(bugs), "/ バージョン", len(byv))
for v in ["0.4.24", "0.5.17", "0.6.12", "0.7.6", "0.8.0", "0.8.30", "0.8.36"]:
    print(v, byv[v]["released"], "既知のバグ", len(byv[v]["bugs"]))
ver = "0.8.30"
print()
print(ver, "一覧とMarketのビルド設定(optimizerオン、via-IRオン、osaka)の照合")
for n in byv[ver]["bugs"]:
    b = bugs[n]
    c = b.get("conditions", {})
    hit = all((evm_ok(val, mine["evmVersion"]) if k == "evmVersion" else mine.get(k) == val) for k, val in c.items())
    print(f"- {b['uid']} {n} | severity {b['severity']} | introduced {b.get('introduced','(なし)')} fixed {b['fixed']} | conditions {c or '(なし: 該当とみなす)'} | 設定の条件 {'一致' if hit else '不一致'}")
    fixed_rel = byv[b["fixed"]]["released"]
    print(f"  修正版 {b['fixed']} 公開日 {fixed_rel}")
