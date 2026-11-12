import json, sys, urllib.request

RPC = "http://127.0.0.1:9107"
DEP = "0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7"  # Deposited
WD = "0xd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb"   # Withdrawn

def rpc(method, params):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
    req = urllib.request.Request(RPC, body, {"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))["result"]

market, state_file = sys.argv[1], sys.argv[2]   # market: アドレスまたは"any"
try:
    state = json.load(open(state_file))
except FileNotFoundError:
    state = {"last": -1, "bal": {}}

latest = int(rpc("eth_blockNumber", []), 16)
start = state["last"] + 1
q = {"fromBlock": hex(start), "toBlock": hex(latest), "topics": [[DEP, WD]]}
if market != "any":
    q["address"] = market
logs = rpc("eth_getLogs", [q]) if start <= latest else []
logs.sort(key=lambda l: (int(l["blockNumber"], 16), int(l["logIndex"], 16)))
for l in logs:
    user = "0x" + l["topics"][2][-40:]
    amount = int(l["data"], 16)
    state["bal"][user] = state["bal"].get(user, 0) + (amount if l["topics"][0] == DEP else -amount)
state["last"] = latest
json.dump(state, open(state_file, "w"))
print("blocks", start, "..", latest, "logs", len(logs))
for user, amount in state["bal"].items():
    print(user, amount)
