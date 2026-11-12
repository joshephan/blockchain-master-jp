"""Marketの運用ツール: 不変条件の監視(キャップストーンの版)。Python標準ライブラリだけ。読み取りのリクエストだけ、鍵を受け取らない。

一回呼ぶたびに一周: indexer.pyでログの帳簿を続きから読む -> 確定の深さのブロック一つをハッシュで決める ->
そのブロックで資産ごとに検査 -> 新しく崩れたものだけ警報、また合えば解消。
  python -I monitor.py <rpc> <market> <インデクサーの状態> <監視の状態> [--timelock アドレス] [--confirm N] [--alerts ファイル] [--hook URL]
                     [--pause マルチシグ:資産=提案番号,...] [--expected 予定ファイル] [--move パーセント] [--second rpc] [--max-age 秒]
  python -I monitor.py --heartbeat <監視の状態> <秒>   最後の周回が何秒前かを確認
検査(設計文書15節):
  照合  ログで数えた金庫のトークン = トークンのbalanceOf(Market)。多ければログなしで入ってきたトークン(K-04)、少なければログなしで出ていったトークン
  合計  アカウントの欄の持ち分の合計 = 合計の欄(I-2)。欄はストレージスロットの地図どおりに読む(2節)
  残高  トークン残高 + 貸し出した借金(totalBorrows) >= 引き出す量(totalDeposits)(I-1)
  出金  持ち分のあるアカウントごとにwithdrawAllをそのアカウントでeth_call(I-5)。ドキュメントに書いた失敗はLOW
  価格  priceOfがリバートしたら(Stopped、ZeroPrice) HIGH(T-01)。直近1分平均が30分平均と--move%を超えて違えばHIGH
  設定  停止ビットが変わったらINFO。タイムロックにMarketを宛先にした予約ができたらINFO、予定ファイルになければHIGH
  健全性 借金のあるアカウントごとに借金の値 / 清算ライン。0.95を超えたらINFO(清算ラインが近い)、1を超えたらINFO(清算できる)
  流出  今回の周回で出ていった量が前のブロックで出ていった量の中央値の10倍を超えたらINFO
ノードの検査(任意): 二つ目のRPCとの高さの差・同じ番号のブロックのハッシュ(--second)、最新ブロックの時刻が何秒前か(--max-age)
"""
import json, os, sys, time, urllib.request
from statistics import median

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import abi  # noqa: E402
import indexer  # noqa: E402

T = abi.load()
F, ERR = T['fn'], T['err']
# 出金の試し呼びでドキュメントに書いた失敗(設計文書3節・6節)
KNOWN = {'InsufficientLiquidity': '残ったトークンを借りていった(F-02)', 'InsufficientCollateral': '借金の上限(F-03)',
         'Stopped': '価格の出どころが停止(T-01)', 'ZeroPrice': '平均価格0(T-01、D-14)'}


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


def slot(url, market, s, at):
    return int(post(url, 'eth_getStorageAt', [market, s, {'blockHash': at}])['result'], 16)


def why(r):
    """リバートデータの先頭4バイトをABIの表のエラー名に"""
    data = r['error'].get('data') or ''
    if isinstance(data, dict):
        data = data.get('data', '')
    sig = ERR.get(str(data)[:10], str(data)[:10] or r['error'].get('message', '')[:40])
    return sig.split('(')[0], sig, data


def load(path):
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    return {'open': {}, 'round': 0, 'paused': {}, 'ops': {}, 'last': None}


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


def round_once(url, market, idx_path, mon_path, o):
    market = market.lower()
    mon = load(mon_path)
    ist, out = indexer.run(url, market, idx_path, o['confirm'], o['timelock'])
    head = int(indexer.rpc(url, 'eth_blockNumber', []), 16)
    n = ist['next'] - 1  # インデクサーが読んだ最後のブロック = 確定の深さのブロック
    b = indexer.rpc(url, 'eth_getBlockByNumber', [hex(n), False])
    at, now = b['hash'], int(b['timestamp'], 16)
    fired, broken = [], set()
    expected = set()
    if o['expected'] and os.path.exists(o['expected']):
        expected = {l.split()[0].lower() for l in open(o['expected'], encoding='utf-8') if l.strip() and not l.startswith('#')}

    def hit(level, key, msg):
        broken.add(key)
        if key not in mon['open']:
            fired.append({'level': level, 'key': key, 'block': n, 'hash': at, 'time': now, 'msg': msg})

    def info(key, msg):
        fired.append({'level': 'INFO', 'key': key, 'block': n, 'hash': at, 'time': now, 'msg': msg})

    if o['second']:  # 二つ目のノード: 高さの差と同じ番号のブロックのハッシュ
        h2 = int(indexer.rpc(o['second'], 'eth_blockNumber', []), 16)
        if abs(head - h2) > 2:
            hit('HIGH', 'node-gap', 'ノードの高さの差 %d (一つ目 %d、二つ目 %d)' % (abs(head - h2), head, h2))
        b2 = indexer.rpc(o['second'], 'eth_getBlockByNumber', [hex(n), False])
        if not b2 or b2['hash'] != at:
            hit('HIGH', 'node-fork', 'ブロック %d のハッシュが違う: 一つ目 %s、二つ目 %s' % (n, at[:10], b2['hash'][:10] if b2 else '不明'))
    if o['max_age'] is not None:
        hb = indexer.rpc(url, 'eth_getBlockByNumber', ['latest', False])
        age = int(time.time()) - int(hb['timestamp'], 16)
        if age > o['max_age']:
            hit('HIGH', 'node-stale', '最新ブロックが %d 秒前(ノードが止まったか遅れている)' % age)
    for line in out:
        if line.startswith('STOP'):
            hit('CRITICAL', 'indexer-stop', 'インデクサー停止: ' + line)
    for oid, op in sorted(ist['ops'].items(), key=lambda x: x[1]['block']):  # タイムロックの予約(設定キーがすること)
        seen = mon['ops'].get(oid)
        if seen == op['state']:
            continue
        left = op['ready'] - now
        if op['state'] == 'scheduled':
            msg = 'タイムロックの予約 %s (作業 %s、ブロック %d、実行可能まで %d 秒)' % (op['fn'], oid[:10], op['block'], max(left, 0))
            if expected and oid.lower() not in expected:
                hit('HIGH', 'op-' + oid, '予定にない ' + msg)
            else:
                info('op-' + oid, msg)
        else:
            info('op-%s-%s' % (oid, op['state']), 'タイムロックの作業 %s %s (%s)' % (oid[:10], {'executed': '実行', 'cancelled': '取り消し'}[op['state']], op['fn']))
        mon['ops'][oid] = op['state']
    for oid, op in ist['ops'].items():  # 予定にない予約は実行・取り消しされるまで開いておく
        if op['state'] == 'scheduled' and expected and oid.lower() not in expected:
            broken.add('op-' + oid)
    rows = []
    for asset in ist['assets']:
        cfg = slot(url, market, abi.slot_config(asset), at)
        bits = (cfg >> 176) & 0xff
        if mon['paused'].get(asset, 0) != bits:
            info('pause-%s-%d' % (asset, n), '資産 %s 停止ビット %d -> %d (1は預け入れ、2は借り入れ)' % (asset[:10], mon['paused'].get(asset, 0), bits))
        mon['paused'][asset] = bits
        bal = uint(url, asset, F['balanceOf(address)'] + w(market), at)
        owed = uint(url, market, F['totalDeposits'] + w(asset), at)  # 預けた人が引き出す量(利息込み、切り捨て)
        debt = uint(url, market, F['totalBorrows'] + w(asset), at)  # 貸し出した借金(利息込み、切り上げ)
        logged = ist['vault'].get(asset, 0)
        sd, sb = slot(url, market, abi.slot_reserve(asset, 0), at), slot(url, market, abi.slot_reserve(asset, 1), at)
        users = sorted(ist['users'].get(asset, {}))
        pos = {u: (slot(url, market, abi.slot_position(asset, u, 0), at), slot(url, market, abi.slot_position(asset, u, 1), at)) for u in users}
        psd, psb = sum(v[0] for v in pos.values()), sum(v[1] for v in pos.values())
        fl = ist['flow'].get(asset, {})
        rows.append('資産 %s 引き出す量 %d トークン残高 %d 貸し出した借金 %d | ログで数えた金庫 %d (預け入れ %d 引き出し %d 借り入れ %d 返済 %d) | 持ち分の合計の欄 %d/%d アカウントの欄の合計 %d/%d(アカウント %d)' % (
            asset[:10], owed, bal, debt, logged, fl.get('deposited', 0), fl.get('withdrawn', 0), fl.get('borrowed', 0),
            fl.get('repaid', 0) + fl.get('liqRepaid', 0), sd, sb, psd, psb, len(pos)))
        if bal > logged:
            hit('LOW', 'match-' + asset, '資産 %s トークン残高 %d > ログで数えた金庫 %d: ログなしで入ってきたトークン %d (K-04、帳簿にない)' % (asset[:10], bal, logged, bal - logged))
        elif bal < logged:
            hit('CRITICAL', 'match-' + asset, '資産 %s トークン残高 %d < ログで数えた金庫 %d: ログなしで出ていったトークン %d' % (asset[:10], bal, logged, logged - bal))
        if (psd, psb) != (sd, sb):
            hit('HIGH', 'sum-' + asset, '資産 %s アカウントの欄の合計 %d/%d != 合計の欄 %d/%d (インデクサーが知らないアカウントまたは帳簿)' % (asset[:10], psd, psb, sd, sb))
        if bal + debt < owed:
            hit('CRITICAL', 'cover-' + asset, '資産 %s トークン残高 %d + 貸し出した借金 %d < 引き出す量 %d (不足 %d)' % (asset[:10], bal, debt, owed, owed - bal - debt))
        p = call(url, market, F['priceOf'] + w(asset), at)
        if 'error' in p:
            name, sig, _ = why(p)
            hit('HIGH', 'feed-' + asset, '資産 %s 価格の読み取りがリバート %s: その資産を担保にしたアカウントの借り入れ・担保の引き出し・清算・借金の消去が停止(T-01)' % (asset[:10], sig))
        elif o['move']:
            feed = '0x' + hex(cfg & ((1 << 160) - 1))[2:].rjust(40, '0')
            c0 = uint(url, feed, F['cumulativePrice(uint32)'] + w(hex(0)), at)
            c1 = uint(url, feed, F['cumulativePrice(uint32)'] + w(hex(60)), at)
            avg30, avg1 = int(p['result'], 16), (c0 - c1) // 60
            if abs(avg1 - avg30) * 100 > o['move'] * avg30:
                hit('HIGH', 'move-' + asset, '資産 %s 直近1分平均 %.4f、30分平均 %.4f (差 %+.1f%%、平均が追いついている途中)' % (
                    asset[:10], avg1 / 1e18, avg30 / 1e18, (avg1 - avg30) * 100 / avg30))
        for u, (d, _) in pos.items():
            if d == 0:
                continue
            r = call(url, market, F['withdrawAll'] + w(asset), at, frm=u)  # withdrawAll(asset)をそのアカウントで試しに呼ぶ
            if 'error' in r:
                name, sig, data = why(r)
                if name in KNOWN and not (name == 'InsufficientLiquidity' and debt == 0):
                    hit('LOW', 'withdraw-%s-%s' % (asset, u), '資産 %s アカウント %s 出金の試し呼び %s (ドキュメントに書いた失敗: %s)' % (asset[:10], u[:10], sig, KNOWN[name]))
                else:  # Panic・未知の失敗、貸し出した借金が0なのに残ったトークンが足りない
                    hit('HIGH', 'withdraw-%s-%s' % (asset, u), '資産 %s アカウント %s 出金の試し呼び失敗 %s %s' % (asset[:10], u[:10], sig, data))
        past = [v for (bn, a, v) in ist['outs'] if a == asset and bn <= (mon['last'] or {}).get('block', -1)]
        now_out = sum(v for (bn, a, v) in ist['outs'] if a == asset and bn > (mon['last'] or {}).get('block', -1))
        if len(past) >= 5 and now_out > 10 * median(past):
            info('out-%s-%d' % (asset, n), '資産 %s 今回の周回で出ていった量 %d、前のブロックで出ていった量の中央値 %d の %.1f 倍' % (asset[:10], now_out, median(past), now_out / median(past)))
    debtors = sorted({u for a in ist['assets'] for u in ist['users'].get(a, {}) if slot(url, market, abi.slot_position(a, u, 1), at)})
    for u in debtors:  # 健全性: 借金の値 / 清算ライン(価格を読めなければ飛ばす、価格の検査が別に通知)
        hv = call(url, market, F['accountHealth'] + w(u), at)
        lv = call(url, market, F['liquidationLimit'] + w(u), at)
        if 'error' in hv or 'error' in lv:
            continue
        dv, lim = int(hv['result'][66:130], 16), int(lv['result'][:66], 16)
        r = dv / lim if lim else float('inf')
        rows.append('アカウント %s 借金の値 %.2f 清算ライン %.2f (%.3f)' % (u[:10], dv / 1e18, lim / 1e18, r))
        if r > 1:
            hit('INFO', 'health-%s' % u, 'アカウント %s 借金の値 %.2f > 清算ライン %.2f: 清算できる' % (u[:10], dv / 1e18, lim / 1e18))
        elif r > 0.95:
            hit('INFO', 'near-%s' % u, 'アカウント %s 借金の値 / 清算ライン %.3f: 清算ラインが近い' % (u[:10], r))
    for key in list(mon['open']):
        if key not in broken:
            fired.append({'level': 'RESOLVED', 'key': key, 'block': n, 'hash': at, 'time': now, 'msg': '解消 ' + key[:60]})
            del mon['open'][key]
    for a in fired:
        if a['level'] in ('CRITICAL', 'HIGH', 'LOW') or (a['level'] == 'INFO' and a['key'].startswith(('health-', 'near-'))):
            mon['open'][a['key']] = a['block']
    mon['round'] += 1
    mon['last'] = {'block': n, 'head': head, 'wall': int(time.time())}
    print('周回 %d | 最新 %d、確認したブロック %d %s' % (mon['round'], head, n, at[:10]))
    for r in rows:
        print('  ' + r)
    for a in fired:
        send(a, o['alerts'], o['hook'])
    hot_all = [a for a in fired if a['level'] == 'CRITICAL' or (a['level'] == 'HIGH' and a['key'].startswith(('feed-', 'move-')))]
    if o['pause'] and hot_all:
        ms, pairs = o['pause'].split(':', 1)
        for pair in pairs.split(','):
            asset, pid = pair.split('=')
            hot = [a for a in hot_all if asset.lower()[:10] in a['msg'].lower()]
            if hot:
                print('  対応の候補: 資産 %s 事前に承認しておいた停止の提案 %s(マルチシグ %s)。署名者一人が execute(%s) = %s%s' % (
                    asset[:10], pid, ms[:10], pid, F['execute(uint256)'], w(hex(int(pid)))))
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
    sys.exit(round_once(a[0], a[1], a[2], a[3], {
        'timelock': opt.get('--timelock'), 'confirm': int(opt.get('--confirm', 0)), 'alerts': opt.get('--alerts'),
        'hook': opt.get('--hook'), 'pause': opt.get('--pause'), 'expected': opt.get('--expected'),
        'move': float(opt['--move']) if '--move' in opt else None, 'second': opt.get('--second'),
        'max_age': int(opt['--max-age']) if '--max-age' in opt else None}))
