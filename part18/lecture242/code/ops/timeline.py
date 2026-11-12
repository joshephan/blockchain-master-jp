"""講義用の事故タイムライン(第242講)。Python標準ライブラリだけを使う。
ブロックを順に読み、Market・マルチシグ・上場トークンへ行った取引と警報の記録をブロック番号順に一つの表にまとめる。
  python -I timeline.py <rpc> <開始ブロック> <終了ブロック> <警報ファイル> <アドレス=名前> ...
"""
import json, sys, urllib.request

SEL = {  # セレクター -> 名前。cast sigで作った値
    '0x47e7ef24': 'deposit', '0xf3fef3a3': 'withdraw', '0xfa09e630': 'withdrawAll', '0x2e49d78b': 'setStatus',
    '0x6127548a': 'addAsset', '0x9d481848': 'propose', '0xb759f954': 'approve', '0xfe0d94c1': 'execute',
    '0x69fe0e2d': 'setFee', '0xa9059cbb': 'transfer',
}


def rpc(url, m, p):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    r = json.load(urllib.request.urlopen(urllib.request.Request(url, body, {'Content-Type': 'application/json'})))
    if 'error' in r:
        raise RuntimeError(r['error'])
    return r['result']


def main(argv):
    url, start, end, alerts = argv[0], int(argv[1]), int(argv[2]), argv[3]
    names = {}
    for kv in argv[4:]:
        k, v = kv.split('=')
        names[k.lower()] = v
    rows = []
    for n in range(start, end + 1):
        b = rpc(url, 'eth_getBlockByNumber', [hex(n), True])
        for tx in b['transactions']:
            to = (tx['to'] or '').lower()
            if to not in names:
                continue
            rc = rpc(url, 'eth_getTransactionReceipt', [tx['hash']])
            what = '%s.%s' % (names[to], SEL.get(tx['input'][:10], tx['input'][:10]))
            frm = names.get(tx['from'].lower(), tx['from'][:10])
            ok = '成功' if rc['status'] == '0x1' else '失敗(status 0)'
            rows.append((n, int(b['timestamp'], 16), '%s <- %s, %s, ログ %d' % (what, frm, ok, len(rc['logs'])), tx['hash'][:12]))
    try:
        for l in open(alerts, encoding='utf-8'):
            a = json.loads(l)
            rows.append((a['block'], a['time'], '警報 [%s] %s' % (a['level'], a['msg'].split(' (tx')[0]), ''))
    except FileNotFoundError:
        pass
    rows.sort(key=lambda r: (r[0], r[2].startswith('警報')))
    t0 = rows[0][1] if rows else 0
    print('| ブロック | 経過(秒) | 起きたこと | tx |')
    print('|---|---|---|---|')
    for n, t, what, h in rows:
        print('| %d | %d | %s | %s |' % (n, t - t0, what, h))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
