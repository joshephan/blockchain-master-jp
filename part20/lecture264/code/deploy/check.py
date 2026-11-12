"""デプロイ後の確認(設計文書14節)。Python標準ライブラリ + cast(keccak)。読み取りのリクエストだけ、鍵を受け取らない。

  python -I deploy/check.py <rpc> <forge scriptの記録 run-latest.json> [--scope audit/scope.md] [--record ファイル]
確認六つ:
 1) デプロイ取引の入力 = ローカルのcreationバイトコード + コンストラクタ引数(引数はほどいて見せる)
 2) チェーンのコード = ローカルのランタイム(immutableの場所だけ隠して比較)、サイズが同じ
 3) immutableの場所の値: Market admin = タイムロック、rateAtKink = 0.05
 4) 末尾のメタデータハッシュがローカルの成果物と同じで、メタデータのsources keccak256がaudit/scope.mdの表と同じ
 5) 座っている席: admin()・guardian()・スロット4、タイムロックの最小待機、デプロイアカウントに管理者ロールなし
 6) コードハッシュ(keccak256(チェーンのコード))の記録
一つでもずれれば終了コード1。ブロックエクスプローラーの検証と同じ比較を自分のノードでする(エクスプローラーに上げる作業はこのツールの外)
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAST = os.path.join(os.path.expanduser('~'), '.foundry', 'bin', 'cast')


def rpc(url, m, p):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    req = urllib.request.Request(url, body, {'Content-Type': 'application/json', 'User-Agent': 'market-deploy-check'})
    r = json.load(urllib.request.urlopen(req, timeout=20))
    if 'error' in r:
        raise RuntimeError(r['error'])
    return r['result']


def keccak(hexdata):
    return subprocess.run([CAST, 'keccak', hexdata], capture_output=True, text=True, check=True).stdout.strip()


def artifact(name):
    path = os.path.join(ROOT, 'out', name + '.sol', name + '.json')
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def tail_hash(code):
    """ランタイムの最後の2バイト = メタデータの末尾の長さ。末尾の中のipfsハッシュ(0x5822の後ろ34バイト)の先頭4バイト(マルチハッシュのヘッダー2バイトを除く)"""
    n = code[-2] << 8 | code[-1]
    tail = code[len(code) - n - 2:]
    k = tail.find(bytes.fromhex('5822'))
    return tail[k + 4:k + 8].hex(), n


def mask(code, refs):
    b = bytearray(code)
    for spots in refs.values():
        for s in spots:
            b[s['start']:s['start'] + s['length']] = bytes(s['length'])
    return bytes(b)


def words(h):
    return [h[i:i + 64] for i in range(0, len(h), 64)]


def scope_table(path):
    """audit/scope.mdの表の最後の欄(メタデータkeccak256の先頭4バイト)。'→'があれば直したビルドの方"""
    out = {}
    for line in open(path, encoding='utf-8'):
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) == 4 and re.search(r'[0-9a-f]{8}$', cells[3]):
            name = cells[0].replace('OpenZeppelin 5.4.0 ', 'lib/openzeppelin-contracts/contracts/')
            out[name] = cells[3].split('→')[-1].strip()
    return out


def main(argv):
    url, run = argv[0], argv[1]
    opt = dict(zip(argv[2::2], argv[3::2]))
    scope = opt.get('--scope', os.path.join(ROOT, 'audit', 'scope.md'))
    rec_path = opt.get('--record')
    with open(run, encoding='utf-8') as f:
        bc = json.load(f)
    chain = int(rpc(url, 'eth_chainId', []), 16)
    made = {t['contractName']: t for t in bc['transactions'] if t['transactionType'] == 'CREATE'}
    rcpt = {r['transactionHash']: r for r in bc['receipts']}
    bad = []
    rec = {'chainId': chain, 'contracts': {}}

    def ok(cond, what):
        print('  %s %s' % ('一致' if cond else '不一致', what))
        if not cond:
            bad.append(what)

    for name in ('TimelockController', 'Market'):
        t = made[name]
        addr = t['contractAddress']
        r = rcpt[t['hash']]
        blk = int(r['blockNumber'], 16)
        a = artifact(name)
        print('== %s %s (ブロック %d, tx %s)' % (name, addr, blk, t['hash']))
        tx = rpc(url, 'eth_getTransactionByHash', [t['hash']])
        init = a['bytecode']['object'][2:]
        inp = tx['input'][2:]
        ok(inp.startswith(init), '1) デプロイ取引の入力の先頭 = ローカルのcreationバイトコード(%d バイト)' % (len(init) // 2))
        args = words(inp[len(init):])
        print('     コンストラクタ引数 %d 個: %s' % (len(args), ', '.join('0x' + w.lstrip('0')[:40] if w.strip('0') else '0' for w in args)))
        code = bytes.fromhex(rpc(url, 'eth_getCode', [addr, hex(blk)])[2:])
        local = bytes.fromhex(a['deployedBytecode']['object'][2:])
        refs = a['deployedBytecode'].get('immutableReferences', {})
        ok(len(code) == len(local), '2) サイズ %d / ローカル %d' % (len(code), len(local)))
        ok(mask(code, refs) == mask(local, refs), '2) immutableの場所 %d か所を隠したランタイム' % sum(len(v) for v in refs.values()))
        imm = {}
        for k in sorted(refs, key=int):  # AST idの順番 = 宣言の順番(Market: admin, rateAtKink)
            s = refs[k][0]['start']
            imm[k] = code[s:s + 32].hex()
        h, n = tail_hash(code)
        ok(h == tail_hash(local)[0], '4) 末尾のメタデータハッシュ %s(末尾 %d バイト)' % (h, n))
        ch = keccak('0x' + code.hex())
        print('  記録 6) コードハッシュ %s' % ch)
        rec['contracts'][name] = {'address': addr, 'tx': t['hash'], 'block': blk, 'runtime': len(code), 'metaHash': h,
                                  'codeHash': ch, 'constructorArgs': ['0x' + w for w in args]}
        if name == 'TimelockController':
            timelock = addr
            deployer = tx['from']
        else:
            vals = list(imm.values())
            ok(int(vals[0], 16) == int(timelock, 16), '3) immutable admin = タイムロック %s' % timelock)
            ok(int(vals[1], 16) == 5 * 10**16, '3) immutable rateAtKink = %d' % int(vals[1], 16))
            meta = a['metadata']['sources']
            want = scope_table(scope)
            for f, v in sorted(meta.items()):
                got = v['keccak256'][2:10]
                ok(want.get(f) == got, '4) sources %s keccak256 %s (scope.md %s、ライセンス %s)' % (f, got, want.get(f), v.get('license')))
            ok(len(meta) == len(want), '4) sourcesのファイル数 %d / scope.md %d' % (len(meta), len(want)))
            market = addr
    print('== 座っている席 (最新ブロック)')
    at = 'latest'

    def call(to, data):
        return rpc(url, 'eth_call', [{'to': to, 'data': data}, at])

    def pad(x):
        return x.lower().replace('0x', '').rjust(64, '0')

    adm = '0x' + call(market, '0xf851a440')[-40:]  # admin()
    gua = '0x' + call(market, '0x452a9320')[-40:]  # guardian()
    slot4 = rpc(url, 'eth_getStorageAt', [market, '0x4', at])
    ok(adm == timelock.lower(), '5) admin() %s' % adm)
    ok(int(slot4, 16) == int(gua, 16), '5) guardian() %s = スロット4' % gua)
    delay = int(call(timelock, '0xf27a0c92'), 16)  # getMinDelay()
    ok(delay == 172800, '5) タイムロックの最小待機 %d 秒' % delay)
    has = int(call(timelock, '0x91d14854' + '0' * 64 + pad(deployer)), 16)  # hasRole(DEFAULT_ADMIN_ROLE, デプロイアカウント)
    ok(has == 0, '5) デプロイアカウント %s にタイムロックの管理者ロールなし' % deployer)
    rec['guardian'] = gua
    rec['deployer'] = deployer
    if rec_path:
        with open(rec_path, 'w', encoding='utf-8') as f:
            json.dump(rec, f, indent=1)
        print('記録: ' + rec_path)
    print('結果: ' + ('確認リストすべて一致' if not bad else 'ずれ %d 件' % len(bad)))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
