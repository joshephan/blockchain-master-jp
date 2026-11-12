"""Marketの運用ツール: Market・タイムロックのログで帳簿を組み立て直すインデクサー。Python標準ライブラリだけ、読み取りのリクエストだけ。

一回呼ぶたびに一周する: 再編成の確認 → 確定の深さまでブロックを一つずつ読む → 状態ファイルの保存。
  python -I indexer.py <rpc> <market> <状態ファイル> [--timelock アドレス] [--confirm N]
ログで数えるもの(キャップストーンの版):
- 資産リスト(AssetListed)、停止ビット(PauseSet)
- 金庫に入っているトークン(資産ごと): 入り = Deposited + Repaid + Liquidated.repaid(借金の資産)、出 = Withdrawn + Borrowed
- 資産ごとに帳簿に欄がありうるアカウント(預け入れ・借り入れ・担保・清算に出てきたアカウント)
- タイムロックの予約(CallScheduled)・実行(CallExecuted)・取り消し(Cancelled)のうち宛先がMarketのもの
- ブロックごとに出ていった量(Withdrawn + Borrowed)、最近の200個
預けた持ち分・借金の持ち分(scaled)はログにない(イベントはトークン量)。持ち分は監視がスロットから読む
"""
import json, os, sys, urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import abi  # noqa: E402

T = abi.load()
EV = T['ev']
KEEP = 64  # ハッシュを覚えておく最近のブロックの数


def rpc(url, m, p):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    r = json.load(urllib.request.urlopen(urllib.request.Request(url, body, {'Content-Type': 'application/json', 'User-Agent': 'market-ops'})))
    if 'error' in r:
        raise RuntimeError(r['error'])
    return r['result']


def addr(topic):
    return '0x' + topic[-40:]


def word(data, i):
    return data[2 + 64 * i: 2 + 64 * (i + 1)]


def load(path, market, timelock):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {'market': market.lower(), 'timelock': (timelock or '').lower(), 'next': 0, 'hashes': {}, 'deltas': {},
            'assets': [], 'paused': {}, 'vault': {}, 'flow': {}, 'users': {}, 'ops': {}, 'outs': []}


def save(path, st):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(st, f, indent=1, sort_keys=True)
    os.replace(tmp, path)  # 書きかけのファイルが残らないように差し替え


def _user(st, a, u, sign):
    d = st['users'].setdefault(a, {})
    d[u] = d.get(u, 0) + sign
    if d[u] <= 0:
        d.pop(u)


def _flow(st, a, kind, amt, sign):
    f = st['flow'].setdefault(a, {})
    f[kind] = f.get(kind, 0) + sign * amt
    if kind in ('deposited', 'repaid', 'liqRepaid'):
        st['vault'][a] = st['vault'].get(a, 0) + sign * amt
    if kind in ('withdrawn', 'borrowed'):
        st['vault'][a] = st['vault'].get(a, 0) - sign * amt


def apply(st, n, ts, logs, sign=1):
    """ログ一つを帳簿の変化量一つに。sign=-1なら取り消し"""
    out = {}
    for l in logs:
        t, d, who = l['topics'], l['data'], l['address'].lower()
        if who == st['timelock']:
            if t[0] == EV['CallScheduled'] and '0x' + word(d, 0)[-40:] == st['market']:
                if sign > 0:
                    blob = d[2 + 64 * 5:]
                    ln = int(blob[:64], 16)
                    call = '0x' + blob[64:64 + 2 * ln]
                    st['ops'][t[1]] = {'state': 'scheduled', 'block': n, 'ready': ts + int(word(d, 4), 16),
                                       'fn': T['name'].get(call[:10], call[:10]), 'data': call}
                else:
                    st['ops'].pop(t[1], None)
            elif t[0] == EV['CallExecuted'] and t[1] in st['ops']:
                st['ops'][t[1]]['state'] = 'executed' if sign > 0 else 'scheduled'
            elif t[0] == EV['Cancelled'] and t[1] in st['ops']:
                st['ops'][t[1]]['state'] = 'cancelled' if sign > 0 else 'scheduled'
            continue
        if t[0] == EV['AssetListed']:
            a = addr(t[1])
            if sign > 0:
                st['assets'].append(a)
            else:
                st['assets'].remove(a)
        elif t[0] == EV['PauseSet']:
            st['paused'][addr(t[1])] = int(d, 16)  # 取り消すときは監視がスロットから読み直す
        elif t[0] in (EV['Deposited'], EV['Withdrawn'], EV['Borrowed'], EV['Repaid']):
            a, u, amt = addr(t[1]), addr(t[2]), int(d, 16)
            kind = {EV['Deposited']: 'deposited', EV['Withdrawn']: 'withdrawn', EV['Borrowed']: 'borrowed', EV['Repaid']: 'repaid'}[t[0]]
            _flow(st, a, kind, amt, sign)
            _user(st, a, u, sign)
            if kind in ('withdrawn', 'borrowed'):
                out[a] = out.get(a, 0) + amt
        elif t[0] == EV['CollateralSet']:
            _user(st, addr(t[1]), addr(t[2]), sign)
        elif t[0] == EV['Liquidated']:
            borrower, liq, colA = addr(t[1]), addr(t[2]), addr(t[3])
            debtA = '0x' + word(d, 0)[-40:]
            _flow(st, debtA, 'liqRepaid', int(word(d, 1), 16), sign)
            _flow(st, colA, 'liqSeized', int(word(d, 2), 16), sign)
            _user(st, colA, liq, sign)
            _user(st, colA, borrower, sign)
            _user(st, debtA, borrower, sign)
        elif t[0] == EV['BadDebtWrittenOff']:
            _flow(st, addr(t[1]), 'writtenOff', int(d, 16), sign)
    if sign > 0:
        for a, v in out.items():
            st['outs'].append([n, a, v])
        st['outs'] = st['outs'][-200:]
    else:
        st['outs'] = [o for o in st['outs'] if o[0] != n]


def run(url, market, path, confirm=0, timelock=None):
    st = load(path, market, timelock)
    head = int(rpc(url, 'eth_blockNumber', []), 16)
    upto = head - confirm
    out = []
    # 1) 再編成の確認: 書いておいた最後のブロックのハッシュが今のノードのハッシュと同じか
    while st['next'] > 0 and str(st['next'] - 1) in st['hashes']:
        n = st['next'] - 1
        b = rpc(url, 'eth_getBlockByNumber', [hex(n), False])
        if b and b['hash'] == st['hashes'][str(n)]:
            break
        if confirm > 0:  # 確定とみなしたブロックが変わった: 直さずに止まる
            out.append(f"STOP: confirmed block {n} changed {st['hashes'][str(n)][:10]} -> {b['hash'][:10] if b else None} (reorg deeper than {confirm})")
            return st, out
        dl = st['deltas'].get(str(n), {'ts': 0, 'logs': []})
        apply(st, n, dl['ts'], dl['logs'], -1)
        out.append(f"reorg: block {n} {st['hashes'][str(n)][:10]} -> {b['hash'][:10] if b else None}, undo {len(dl['logs'])} logs")
        st['hashes'].pop(str(n)); st['deltas'].pop(str(n), None)
        st['next'] = n
    else:
        if st['next'] > 0 and str(st['next'] - 1) not in st['hashes']:
            out.append(f"STOP: block {st['next'] - 1} hash not kept (reorg deeper than kept window)")
            save(path, st)
            return st, out
    # 2) 確定の深さまでブロックを一つずつ。アドレス二つ(Market、タイムロック)を一度に聞く
    who = [st['market']] + ([st['timelock']] if st['timelock'] else [])
    n = st['next']
    while n <= upto:
        b = rpc(url, 'eth_getBlockByNumber', [hex(n), False])
        if n > 0 and str(n - 1) in st['hashes'] and b['parentHash'] != st['hashes'][str(n - 1)]:
            out.append(f"parent mismatch at {n}, retry next round")
            break
        logs = rpc(url, 'eth_getLogs', [{'address': who, 'blockHash': b['hash']}])  # ハッシュで聞く: このブロックのログだけ
        ts = int(b['timestamp'], 16)
        apply(st, n, ts, logs)
        st['hashes'][str(n)] = b['hash']
        if logs:
            st['deltas'][str(n)] = {'ts': ts, 'logs': logs}
            out.append(f"block {n} {b['hash'][:10]} logs {len(logs)}")
        for old in [k for k in st['hashes'] if int(k) < n - KEEP]:
            st['hashes'].pop(old); st['deltas'].pop(old, None)
        n += 1
        st['next'] = n
    save(path, st)
    return st, out


if __name__ == '__main__':
    url, market, path = sys.argv[1:4]
    opt = dict(zip(sys.argv[4::2], sys.argv[5::2]))
    st, out = run(url, market, path, int(opt.get('--confirm', 0)), opt.get('--timelock'))
    print('\n'.join(out))
    print(json.dumps({'next': st['next'], 'vault': st['vault'], 'assets': st['assets'], 'ops': len(st['ops'])}))
