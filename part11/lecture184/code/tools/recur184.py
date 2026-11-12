import json, sys, collections
j = json.load(open(sys.argv[1], encoding="utf-8"))
calls = collections.defaultdict(set); names = {}
def walk(n, cur, path):
    if isinstance(n, dict):
        if n.get("nodeType") in ("FunctionDefinition", "ModifierDefinition"):
            cur = n["id"]; names[cur] = f"{path}:{n.get('name') or n.get('kind')}"
        if n.get("nodeType") in ("Identifier", "MemberAccess", "IdentifierPath"):
            r = n.get("referencedDeclaration")
            if cur is not None and r is not None: calls[cur].add(r)
        for v in n.values(): walk(v, cur, path)
    elif isinstance(n, list):
        for v in n: walk(v, cur, path)
for p, s in j["sources"].items(): walk(s["AST"], None, p)
fn = set(names)
g = {a: {b for b in bs if b in fn} for a, bs in calls.items() if a in fn}
cyc = []
def has_path(a, b, seen):
    if a == b: return True
    seen.add(a)
    return any(has_path(x, b, seen) for x in g.get(a, ()) if x not in seen)
for u in fn:
    for v in g.get(u, ()):
        if has_path(v, u, set()): cyc.append((names[u], names[v]))
print("srcの関数・modifier", len(fn), "/ 関数同士が呼ぶ辺", sum(len(v) for v in g.values()), "/ 循環に含まれる辺", len(cyc))
for c in cyc: print(" ", c)
