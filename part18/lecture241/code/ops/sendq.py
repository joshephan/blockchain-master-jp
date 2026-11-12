"""Marketの運用ツール: 運用アカウント一つの送信キュー(第239講・第240講)。署名・送信をする最初のツール。一つのアカウントのナンスはこのキュー一つだけが採番する。Python標準ライブラリ + cast(署名・calldata)。

日誌(journal)ファイル一つに仕事ごと: id、やること、ナンス、署名した取引(raws)、ハッシュ(hashes)、状態。
状態: new → signed(送る前に日誌に先に書く) → sent → mined → done(確定の深さ)
      failed(ブロックに入ったがstatus 0) / estimate_failed(送らない、番号を使わない) / send_error・conflict(停止)
  python -I sendq.py <rpc> <日誌> <秘密鍵> [--crash-after-send <id>] [--confirm N]
"""
import json, os, subprocess, sys, urllib.request

BIN = os.path.join(os.path.expanduser('~'), '.foundry', 'bin')


def rpc(url, m, p, raw=False):
    body = json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': m, 'params': p}).encode()
    r = json.load(urllib.request.urlopen(urllib.request.Request(url, body, {'Content-Type': 'application/json', 'User-Agent': 'market-ops'})))
    if raw:
        return r
    if 'error' in r:
        raise RuntimeError(r['error'])
    return r['result']


def load(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def save(path, j):
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(j, f, indent=1)
    os.replace(tmp, path)  # 書きかけの日誌が残らないように差し替え


def cast(*args):
    r = subprocess.run([os.path.join(BIN, 'cast.exe'), *args], capture_output=True, text=True, encoding='utf-8')
    if r.returncode:
        raise RuntimeError(r.stderr.strip())
    return r.stdout.strip()


def sign(url, key, job, nonce, gas, fee, tip):
    return cast('mktx', job['to'], job['sig'], *job['args'], '--private-key', key, '--nonce', str(nonce),
                '--gas-limit', str(gas), '--gas-price', str(fee), '--priority-gas-price', str(tip), '--rpc-url', url)


def estimate(url, frm, job, block='latest'):
    data = cast('calldata', job['sig'], *job['args'])
    r = rpc(url, 'eth_estimateGas', [{'from': frm, 'to': job['to'], 'data': data}, block], raw=True)
    return r.get('result'), r.get('error')


def _send(url, job):
    r = rpc(url, 'eth_sendRawTransaction', [job['raws'][-1]], raw=True)
    return r.get('result') or r.get('error', {}).get('message')


def step(url, path, key, crash_after_send=None, margin=0, confirm=0):
    """一周: 送った取引のレシートの確認(複数のハッシュのどれでも) → 消えたものは書いておいた取引をそのまま送り直す → 新しい仕事。"""
    j = load(path)
    log = []
    frm = j['from']
    head = int(rpc(url, 'eth_blockNumber', []), 16)
    latest_nonce = int(rpc(url, 'eth_getTransactionCount', [frm, 'latest']), 16)
    if j.get('next_nonce') is None:  # 最初の一回だけノードに聞く。そのあとは日誌が採番する
        j['next_nonce'] = latest_nonce
    for job in j['jobs']:
        if job['state'] not in ('signed', 'sent', 'mined'):
            continue
        rc = None
        for h in job['hashes']:  # 同じナンスで差し替えて送った取引があればハッシュが複数
            rc = rpc(url, 'eth_getTransactionReceipt', [h])
            if rc:
                break
        if rc:
            st = 'mined' if rc['status'] == '0x1' else 'failed'
            blk = int(rc['blockNumber'], 16)
            if st == 'mined' and head - blk >= confirm:
                st = 'done'
            if (st, blk) != (job['state'], job.get('block')):
                job.update(state=st, block=blk, gasUsed=int(rc['gasUsed'], 16), by=rc['transactionHash'])
                log.append(f"{job['id']} nonce {job['nonce']} {st} block {blk} gasUsed {job['gasUsed']} by {rc['transactionHash'][:10]} (hashes {len(job['hashes'])})")
            continue
        if job['state'] == 'mined':
            log.append(f"{job['id']} nonce {job['nonce']} receipt gone (block {job['block']} replaced)")
        if latest_nonce > job['nonce']:  # この番号はもう使われたのに自分のハッシュはどこにもない
            job['state'] = 'conflict'
            log.append(f"{job['id']} nonce {job['nonce']} used by another tx, queue stops")
            save(path, j)
            return j, log
        job['state'] = 'sent'
        log.append(f"{job['id']} nonce {job['nonce']} resend same raw -> {_send(url, job)}")
    for job in j['jobs']:
        if job['state'] != 'new':
            continue
        g, err = estimate(url, frm, job)
        if err:
            job['state'] = 'estimate_failed'
            job['error'] = err
            log.append(f"{job['id']} estimate failed, not sent, nonce {j['next_nonce']} not used: {err.get('message', '').split(':')[0]}: {err.get('data', '')}")
            continue
        gas = int(g, 16) * (100 + margin) // 100
        job.update(nonce=j['next_nonce'], gas=gas, fee=j['fee'], tip=j['tip'])
        raw = sign(url, key, job, job['nonce'], gas, j['fee'], j['tip'])
        job['raws'] = [raw]
        job['hashes'] = [cast('keccak', raw)]
        job['state'] = 'signed'
        j['next_nonce'] += 1
        save(path, j)  # 送る前に先に書く
        r = _send(url, job)
        if crash_after_send is not None and job['id'] == crash_after_send:
            log.append(f"{job['id']} nonce {job['nonce']} sent, CRASH before writing 'sent'")
            return j, log
        if not r.startswith('0x'):  # ノードが拒否: 別の場所でこのアカウントの番号を使ったかもしれない
            job['state'] = 'send_error'
            job['error'] = r
            log.append(f"{job['id']} nonce {job['nonce']} REJECTED {r}, queue stops")
            save(path, j)
            return j, log
        job['state'] = 'sent'
        log.append(f"{job['id']} nonce {job['nonce']} gas {gas} sent -> {r[:10]}")
        save(path, j)
    save(path, j)
    return j, log


def bump(url, path, key, job_id, pct):
    """詰まった仕事を同じナンス、手数料をpct%上げて署名し直して送る。古いハッシュも日誌に残す。"""
    j = load(path)
    job = next(x for x in j['jobs'] if x['id'] == job_id)
    fee, tip = job['fee'] * (100 + pct) // 100, job['tip'] * (100 + pct) // 100
    raw = sign(url, key, job, job['nonce'], job['gas'], fee, tip)
    r = rpc(url, 'eth_sendRawTransaction', [raw], raw=True)
    r = r.get('result') or r.get('error', {}).get('message')
    if r.startswith('0x'):
        job.update(fee=fee, tip=tip)
        job['raws'].append(raw)
        job['hashes'].append(cast('keccak', raw))
        save(path, j)
    return f"{job_id} nonce {job['nonce']} bump {pct}% fee {fee} tip {tip} -> {r[:66]}"


if __name__ == '__main__':
    url, path, key = sys.argv[1:4]
    c = sys.argv[sys.argv.index('--crash-after-send') + 1] if '--crash-after-send' in sys.argv else None
    conf = int(sys.argv[sys.argv.index('--confirm') + 1]) if '--confirm' in sys.argv else 0
    j, log = step(url, path, key, c, confirm=conf)
    print('\n'.join(log))
