"""Marketの運用ツール1: 複数のRPCに同じブロックハッシュでMarketの状態を聞き、答えを並べる。

使い方: python -I ops/market_read.py <Marketのアドレス> <資産のアドレス> <RPC 1> [RPC 2 ...] [--tag latest|safe|finalized]
- 基準ブロック: RPC 1がそのタグで教えたブロックのハッシュ
- すべてのRPCに同じハッシュで聞く(EIP-1898 blockHash)。そのブロックを知らないRPCは"不明"
- 答えが一つでも違うか、知らないRPCがあれば終了コード1
- 読み取りのリクエストだけを送る。署名・送信なし
"""
import json
import sys
import urllib.error
import urllib.request

SELECTORS = {  # 関数名と4バイト(cast sigの値)
    'status()': '0x200d2ed2',
    'assetCount()': '0xeafe7a74',
    'totalDeposits(address)': '0xe9403256',
}


def rpc(url, method, params):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}).encode()
    req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'market-ops'})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        return {'error': {'code': e.code, 'message': e.read().decode('utf-8', 'replace')[:120]}}
    except OSError as e:
        return {'error': {'code': 0, 'message': str(e)[:120]}}


def read_all(url, market, asset, block_hash):
    at = {'blockHash': block_hash}
    out = {}
    for name, data in [('status', SELECTORS['status()']),
                       ('assetCount', SELECTORS['assetCount()']),
                       ('totalDeposits', SELECTORS['totalDeposits(address)'] + asset[2:].lower().rjust(64, '0'))]:
        r = rpc(url, 'eth_call', [{'to': market, 'data': data}, at])
        out[name] = int(r['result'], 16) if 'result' in r else '不明(' + str(r['error'].get('message'))[:40] + ')'
    return out


def main(argv):
    tag = 'latest'
    if '--tag' in argv:
        i = argv.index('--tag')
        tag = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    market, asset, urls = argv[0], argv[1], argv[2:]
    head = rpc(urls[0], 'eth_getBlockByNumber', [tag, False])['result']
    block_hash, number = head['hash'], int(head['number'], 16)
    print(f'基準ブロック: {tag} {number} {block_hash} (RPC 1が教えたもの)')
    rows = []
    for u in urls:
        rows.append((u, read_all(u, market, asset, block_hash)))
    names = ['status', 'assetCount', 'totalDeposits']
    print('RPC'.ljust(28) + ''.join(n.ljust(30) for n in names))
    for u, r in rows:
        print(u.ljust(28) + ''.join(str(r[n]).ljust(30) for n in names))
    bad = False
    for n in names:
        vals = {str(r[n]) for _, r in rows}
        if len(vals) > 1 or any(str(v).startswith('不明') for v in vals):
            print(f'違い: {n} -> {sorted(vals)}')
            bad = True
    print('結果:', 'ずれあり' if bad else 'すべてのRPCが同じ答え')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
