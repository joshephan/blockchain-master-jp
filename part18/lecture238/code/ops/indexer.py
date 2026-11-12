"""Marketの運用ツール: Marketのログで帳簿を組み立て直すインデクサー(第238講)。Python標準ライブラリだけ、読み取りのリクエストだけ。

一回呼ぶたびに一周する: 再編成の確認 → 確定の深さまでブロックを一つずつ読む → 状態ファイルの保存。
  python -I indexer.py <rpc> <market> <状態ファイル> [--confirm N] [--naive]
--naive: ブロックハッシュを書かずにブロック番号だけでつないで読む版(比較用)
"""
import json, os, sys, urllib.request

T_ASSET = '0x57c9e281a77ac9ba91a9f926dda440cd98f47ee4f2d5030b5d54688cecbc9989'  # AssetAdded(address,uint8)
T_STATUS = '0xe1377aa21d49fa10bb9ece6a0cd4f75597a90a80c3750f7f7674967f49ab9a62'  # StatusChanged(uint8,uint8)
T_DEP = '0x8752a472e571a816aea92eec8dae9baf628e840f4929fbcc2d155e6233ff68a7'  # Deposited(address,address,uint256)
T_WD = '0xd1c19fbcd4551a5edfb66d43d2e337c04837afda3482b42bdf569a8fccdae5fb'  # Withdrawn(address,address,uint256)
KEEP = 64  # ハッシュを覚えておく最近のブロックの数


def rpc(url, m, p):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    r = json.load(urllib.request.urlopen(urllib.request.Request(url, body, {'Content-Type': 'application/json', 'User-Agent': 'market-ops'})))
    if 'error' in r:
        raise RuntimeError(r['error'])
    return r['result']


def addr(topic):
    return '0x' + topic[-40:]


def load(path, market):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {'market': market.lower(), 'next': 0, 'hashes': {}, 'deltas': {}, 'pos': {}, 'total': {}, 'assets': [],
            'status': 0, 'skipped': 0}


def save(path, st):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(st, f, indent=1, sort_keys=True)
    os.replace(tmp, path)  # 書きかけのファイルが残らないように差し替え


def apply(st, n, logs, sign=1):
    """ログ一つを帳簿の変化量一つに。sign=-1なら取り消し。"""
    for l in logs:
        t = l['topics']
        if t[0] in (T_DEP, T_WD):
            if len(t) != 3:  # 同じシグネチャで別のindexed配置のものは読まずに数えるだけ
                st['skipped'] += sign
                continue
            a, u, amt = addr(t[1]), addr(t[2]), int(l['data'], 16)
            d = amt if t[0] == T_DEP else -amt
            d *= sign
            st['pos'].setdefault(a, {})
            st['pos'][a][u] = st['pos'][a].get(u, 0) + d
            st['total'][a] = st['total'].get(a, 0) + d
        elif t[0] == T_ASSET:
            a = addr(t[1])
            if sign > 0:
                st['assets'].append(a)
            else:
                st['assets'].remove(a)
        elif t[0] == T_STATUS:
            w = l['data'][2:]
            frm, to = int(w[:64], 16), int(w[64:], 16)
            st['status'] = to if sign > 0 else frm


def run(url, market, path, confirm=0, naive=False):
    st = load(path, market)
    head = int(rpc(url, 'eth_blockNumber', []), 16)
    upto = head - confirm
    out = []
    if naive:
        if upto >= st['next']:
            logs = rpc(url, 'eth_getLogs', [{'address': market, 'fromBlock': hex(st['next']), 'toBlock': hex(upto)}])
            for l in logs:
                apply(st, int(l['blockNumber'], 16), [l])
            out.append(f"read {st['next']}..{upto} logs {len(logs)}")
            st['next'] = upto + 1
        save(path, st)
        return st, out
    # 1) 再編成の確認: 書いておいた最後のブロックのハッシュが今のノードのハッシュと同じか
    while st['next'] > 0 and str(st['next'] - 1) in st['hashes']:
        n = st['next'] - 1
        b = rpc(url, 'eth_getBlockByNumber', [hex(n), False])
        if b and b['hash'] == st['hashes'][str(n)]:
            break
        if confirm > 0:  # 確定とみなしたブロックが変わった: 直さずに止まる
            out.append(f"STOP: confirmed block {n} changed {st['hashes'][str(n)][:10]} -> {b['hash'][:10] if b else None} (reorg deeper than {confirm})")
            return st, out
        apply(st, n, st['deltas'].get(str(n), []), -1)
        out.append(f"reorg: block {n} {st['hashes'][str(n)][:10]} -> {b['hash'][:10] if b else None}, undo {len(st['deltas'].get(str(n), []))} logs")
        st['hashes'].pop(str(n)); st['deltas'].pop(str(n), None)
        st['next'] = n
    else:
        if st['next'] > 0 and str(st['next'] - 1) not in st['hashes']:
            out.append(f"STOP: block {st['next'] - 1} hash not kept (reorg deeper than kept window)")
            save(path, st)
            return st, out
    # 2) 確定の深さまでブロックを一つずつ
    n = st['next']
    while n <= upto:
        b = rpc(url, 'eth_getBlockByNumber', [hex(n), False])
        if n > 0 and str(n - 1) in st['hashes'] and b['parentHash'] != st['hashes'][str(n - 1)]:
            out.append(f"parent mismatch at {n}, retry next round")
            break
        logs = rpc(url, 'eth_getLogs', [{'address': market, 'blockHash': b['hash']}])  # ハッシュで聞く: このブロックのログだけ
        apply(st, n, logs)
        st['hashes'][str(n)] = b['hash']
        if logs:
            st['deltas'][str(n)] = logs
        for old in [k for k in st['hashes'] if int(k) < n - KEEP]:
            st['hashes'].pop(old); st['deltas'].pop(old, None)
        if logs:
            out.append(f"block {n} {b['hash'][:10]} logs {len(logs)}")
        n += 1
        st['next'] = n
    save(path, st)
    return st, out


def check(url, st, block_hash):
    """同じブロックでチェーンの状態と照らし合わせる(EIP-1898 blockHashでeth_call)。"""
    res = []
    for a, total in st['total'].items():
        data = '0xe9403256' + a[2:].rjust(64, '0')  # totalDeposits(address)
        chain = int(rpc(url, 'eth_call', [{'to': st['market'], 'data': data}, {'blockHash': block_hash}]), 16)
        res.append(('total', a, total, chain))
        for u, amt in st['pos'].get(a, {}).items():
            data = '0x4bd21445' + a[2:].rjust(64, '0') + u[2:].rjust(64, '0')  # positions(address,address)
            r = rpc(url, 'eth_call', [{'to': st['market'], 'data': data}, {'blockHash': block_hash}])
            res.append(('pos', u, amt, int(r[2:66], 16)))
    return res


if __name__ == '__main__':
    url, market, path = sys.argv[1:4]
    confirm = int(sys.argv[sys.argv.index('--confirm') + 1]) if '--confirm' in sys.argv else 0
    st, out = run(url, market, path, confirm, '--naive' in sys.argv)
    print('\n'.join(out))
    print(json.dumps({'next': st['next'], 'total': st['total'], 'pos': st['pos']}))
