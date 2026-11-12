import json, sys, subprocess, pathlib
solc = "solc-0.8.30"
d = pathlib.Path(sys.argv[1])
for f in sorted(d.glob("*.sol")):
    inp = {"language": "Solidity", "sources": {f.name: {"content": f.read_text(encoding="utf-8")}},
           "settings": {"outputSelection": {"*": {"*": []}}}}
    r = subprocess.run([solc, "--standard-json"], input=json.dumps(inp), capture_output=True, text=True, encoding="utf-8")
    out = json.loads(r.stdout)
    errs = [e for e in out.get("errors", []) if e["severity"] == "error"] or out.get("errors", [])
    for e in errs[:2]:
        print(f"{f.stem:22} {e['type']}({e.get('errorCode')}) {e['message'][:110]}")
    if not errs: print(f"{f.stem:22} (エラーなし)")
