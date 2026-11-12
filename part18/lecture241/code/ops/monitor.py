"""Marketの運用ツール: 不変条件の監視(第241講)。Python標準ライブラリだけ。読み取りのリクエストだけ、鍵を受け取らない。

一回呼ぶたびに一周: indexer.pyでログの帳簿を続きから読む -> 確定の深さのブロック一つをハッシュで決める ->
そのブロックで資産ごとに検査四つ -> 新しく崩れたものだけ警報、また合えば解消。
  python -I monitor.py <rpc> <market> <インデクサーの状態> <監視の状態> [--confirm N] [--alerts ファイル] [--hook URL] [--pause マルチシグ:提案番号]
                     [--second rpc] [--max-age 秒]
  python -I monitor.py --heartbeat <監視の状態> <秒>   最後の周回が何秒前かを確認
検査: 照合(インデクサーの帳簿 = チェーンの欄、第238講) / 合計(アカウントの欄の合計 = 合計の欄) / 残高(トークン残高 + 貸し出した借金 >= 引き出す量) / 出金(持ち分のあるアカウントごとにwithdrawAllをeth_call)
第53章の版: 欄には利息の指数で割った持ち分が入る。引き出す量 = 合計の欄 x 預け入れ側の指数、貸し出した借金 = 借りた持ち分の合計 x 借り入れ側の指数(reservesの欄、0は1)
ノードの検査(任意): 二つ目のRPCとの高さの差・同じ番号のブロックのハッシュ(--second)、最新ブロックの時刻が何秒前か(--max-age)
"""
import json, os, sys, time, urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import indexer  # noqa: E402  同じopsフォルダーの第238講のインデクサー

STATUS = ['Active', 'DepositPaused', 'Frozen']


def post(url, m, p):
    """エラーを例外に変えず応答をそのまま返す(リバートデータを読むため)"""
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    req = urllib.request.Request(url, body, {'Content-Type': 'application/json', 'User-Agent': 'market-ops'})
    return json.load(urllib.request.urlopen(req))


def w(a):
    return a.lower().replace('0x', '').rjust(64, '0')


def call(url, to, data, at, frm=None):
    tx = {'to': to, 'data': data}
    if frm:
        tx['from'] = frm
    return post(url, 'eth_call', [tx, {'blockHash': at}])


def uint(url, to, data, at):
    return int(call(url, to, data, at)['result'][:66], 16)


def load(path):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {'open': {}, 'round': 0, 'status': None, 'last': None}


def save(path, st):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(st, f, indent=1, sort_keys=True)
    os.replace(tmp, path)


def send(a, alerts, hook):
    line = json.dumps(a, ensure_ascii=False)
    print('  [%s] %s' % (a['level'], a['msg']))
    if alerts:
        with open(alerts, 'a', encoding='utf-8') as f:
            f.write(line + '\n')
    if hook:
        try:
            urllib.request.urlopen(urllib.request.Request(hook, line.encode(), {'Content-Type': 'application/json'}), timeout=3)
        except Exception as e:  # 通知の道が切れても監視は続ける。切れた事実は画面に残す
            print('  [通知失敗] %s' % e)


def round_once(url, market, idx_path, mon_path, confirm, alerts, hook, pause, second=None, max_age=None):
    market = market.lower()
    mon = load(mon_path)
    ist, out = indexer.run(url, market, idx_path, confirm)
    head = int(indexer.rpc(url, 'eth_blockNumber', []), 16)
    n = ist['next'] - 1  # インデクサーが読んだ最後のブロック = 確定の深さのブロック
    b = indexer.rpc(url, 'eth_getBlockByNumber', [hex(n), False])
    at, now = b['hash'], int(b['timestamp'], 16)
    fired, broken = [], set()

    def hit(level, key, msg):
        broken.add(key)
        if key not in mon['open']:
            fired.append({'level': level, 'key': key, 'block': n, 'hash': at, 'time': now, 'msg': msg})

    if second:  # 二つ目のノード: 高さの差と同じ番号のブロックのハッシュ
        h2 = int(indexer.rpc(second, 'eth_blockNumber', []), 16)
        if abs(head - h2) > 2:
            hit('HIGH', 'node-gap', 'ノードの高さの差 %d (一つ目 %d、二つ目 %d)' % (abs(head - h2), head, h2))
        b2 = indexer.rpc(second, 'eth_getBlockByNumber', [hex(n), False])
        if not b2 or b2['hash'] != at:
            hit('HIGH', 'node-fork', 'ブロック %d のハッシュが違う: 一つ目 %s、二つ目 %s' % (n, at[:10], b2['hash'][:10] if b2 else '不明'))
    if max_age is not None:
        hb = indexer.rpc(url, 'eth_getBlockByNumber', ['latest', False])
        age = int(time.time()) - int(hb['timestamp'], 16)
        if age > max_age:
            hit('HIGH', 'node-stale', '最新ブロックが %d 秒前(ノードが止まったか遅れている)' % age)
    for line in out:
        if line.startswith('STOP'):
            hit('CRITICAL', 'indexer-stop', 'インデクサー停止: ' + line)
    status = uint(url, market, '0x200d2ed2', at)  # status()
    if mon['status'] is not None and status != mon['status']:
        fired.append({'level': 'INFO', 'key': 'status-%d' % n, 'block': n, 'hash': at, 'time': now,
                      'msg': 'マーケットの状態 %s -> %s' % (STATUS[mon['status']], STATUS[status])})
    mon['status'] = status
    rows = []
    for asset in ist['assets']:
        ledger = uint(url, market, '0xe9403256' + w(asset), at)  # totalDeposits(address)
        bal = uint(url, asset, '0x70a08231' + w(market), at)  # balanceOf(address)
        pos = {u: uint(url, market, '0x4bd21445' + w(asset) + w(u), at) for u in ist['pos'].get(asset, {})}  # positions
        s, mine = sum(pos.values()), ist['total'].get(asset, 0)
        rv = call(url, market, '0xd66bd524' + w(asset), at)['result'][2:]  # reserves(address): 借り入れ側の指数、預け入れ側の指数、時刻
        bi, si = int(rv[:64], 16) or 10**18, int(rv[64:128], 16) or 10**18  # 最後に書いた指数(0は1)
        owed = ledger * si // 10**18  # 預けた人が引き出す量(切り捨て)
        debt = -(-uint(url, market, '0x8d730124' + w(asset), at) * bi // 10**18)  # totalBorrows(address) x 指数、貸し出した借金(切り上げ)
        rows.append('資産 %s 合計の欄 %d 引き出す量 %d トークン残高 %d 貸し出した借金 %d アカウントの欄の合計 %d(アカウント %d) インデクサーの帳簿 %d' % (
            asset[:10], ledger, owed, bal, debt, s, len(pos), mine))
        if mine != ledger or any(ist['pos'][asset][u] != v for u, v in pos.items()):
            hit('HIGH', 'match-' + asset, '資産 %s インデクサーの帳簿 %d != チェーンの合計の欄 %d (インデクサー側から確認)' % (asset[:10], mine, ledger))
        if s != ledger:
            hit('CRITICAL', 'sum-' + asset, '資産 %s アカウントの欄の合計 %d != 合計の欄 %d' % (asset[:10], s, ledger))
        if bal + debt < owed:
            hit('CRITICAL', 'cover-' + asset, '資産 %s トークン残高 %d + 貸し出した借金 %d < 引き出す量 %d (不足 %d)' % (
                asset[:10], bal, debt, owed, owed - bal - debt))
        for u, d in pos.items():
            if d == 0:
                continue
            r = call(url, market, '0xfa09e630' + w(asset), at, frm=u)  # withdrawAll(address)をそのアカウントで試しに呼ぶ
            if 'error' in r:
                why = r['error'].get('data') or r['error'].get('message')
                sel = str(why)[:10]
                if (sel == '0xa17e11d5' and debt > 0) or sel == '0xb07e3bc4':  # ドキュメントに書いた失敗: InsufficientLiquidity(貸し出し中)・InsufficientCollateral(借金の上限)
                    hit('LOW', 'withdraw-%s-%s' % (asset, u), '資産 %s アカウント %s 持ち分 %d 出金の試し呼び %s (ドキュメントに書いた失敗: %s)' % (
                        asset[:10], u[:10], d, why[:10], '残ったトークンを借りていった' if sel == '0xa17e11d5' else '借金の上限'))
                else:  # Panic・未知の失敗、貸し出した借金が0なのに残ったトークンが足りない
                    hit('HIGH', 'withdraw-%s-%s' % (asset, u), '資産 %s アカウント %s 持ち分 %d 出金の試し呼び失敗 %s' % (asset[:10], u[:10], d, why))
    for key in list(mon['open']):
        if key not in broken:
            fired.append({'level': 'RESOLVED', 'key': key, 'block': n, 'hash': at, 'time': now, 'msg': '解消 ' + key[:60]})
            del mon['open'][key]
    for a in fired:
        if a['level'] in ('CRITICAL', 'HIGH', 'LOW'):
            mon['open'][a['key']] = a['block']
    mon['round'] += 1
    mon['last'] = {'block': n, 'head': head, 'wall': int(time.time())}
    print('周回 %d | 最新 %d、確認したブロック %d %s | マーケットの状態 %s' % (mon['round'], head, n, at[:10], STATUS[status]))
    for r in rows:
        print('  ' + r)
    for a in fired:
        send(a, alerts, hook)
    if any(a['level'] == 'CRITICAL' for a in fired) and status == 0:
        if pause:
            ms, pid = pause.split(':')
            print('  対応: 事前に承認しておいた停止の提案 %s 番号 %s。署名者一人が execute(%s) = 0xfe0d94c1%s' % (ms[:10], pid, pid, w(hex(int(pid)))))
        print('  対応: 預け入れの停止 setStatus(1) calldata 0x2e49d78b%s (宛先はMarket)' % w('0x1'))
    if mon['open']:
        print('  開いている警報 %d 件' % len(mon['open']))
    elif not fired:
        print('  異常なし')
    save(mon_path, mon)
    return 1 if mon['open'] else 0


def heartbeat(path, max_age):
    mon = load(path)
    age = int(time.time()) - mon['last']['wall']
    if age > max_age:
        print('[CRITICAL] 監視が %d 秒間回っていない(最後に確認したブロック %d)' % (age, mon['last']['block']))
        return 1
    print('監視正常: 最後の周回 %d 秒前、確認したブロック %d' % (age, mon['last']['block']))
    return 0


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == '--heartbeat':
        sys.exit(heartbeat(a[1], int(a[2])))
    opt = dict(zip(a[4::2], a[5::2]))
    sys.exit(round_once(a[0], a[1], a[2], a[3], int(opt.get('--confirm', 0)), opt.get('--alerts'), opt.get('--hook'), opt.get('--pause'),
                        opt.get('--second'), int(opt['--max-age']) if '--max-age' in opt else None))
