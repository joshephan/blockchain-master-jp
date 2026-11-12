"""運用ツールが共有するABIの表。abi/IMarket.json(ciの7段階目がビルドと同じかを見る)からセレクター・トピック・エラーを計算する。手で書いた4バイトはない。

Marketの外のもの(トークン、タイムロック、マルチシグ、テスト用の価格の出どころ)はシグネチャの文字列だけ書いて同じkeccakで計算する
  python -I ops/abi.py --check   運用ツールが使う名前がABIファイルに全部あるか(ciの8段階目)
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mpt import keccak  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ABI = os.path.join(ROOT, 'abi', 'IMarket.json')

# Marketの外のシグネチャ(このツールが呼ぶか読むものだけ)
OUTSIDE_FN = ['balanceOf(address)', 'cumulativePrice(uint32)',  # トークン、価格の出どころ
              'propose(address,bytes)', 'approve(uint256)', 'execute(uint256)',  # マルチシグ(テスト用の代役)
              'schedule(address,uint256,bytes,bytes32,bytes32,uint256)',
              'execute(address,uint256,bytes,bytes32,bytes32)', 'cancel(bytes32)']  # タイムロック
OUTSIDE_EV = ['CallScheduled(bytes32,uint256,address,uint256,bytes,bytes32,uint256)',
              'CallExecuted(bytes32,uint256,address,uint256,bytes)', 'Cancelled(bytes32)']
OUTSIDE_ERR = ['Stopped()', 'ShortHistory(uint256,uint256)', 'Panic(uint256)', 'Error(string)']
# 運用ツールが使うMarketの名前(ABIファイルになければciで止まる)
USED = ['assetCount', 'totalDeposits', 'totalBorrows', 'priceOf', 'accountHealth', 'liquidationLimit',
        'withdrawAll', 'pause', 'unpause', 'listAsset', 'setSupplyCap', 'setGuardian',
        'AssetListed', 'PauseSet', 'SupplyCapSet', 'GuardianSet', 'Deposited', 'Withdrawn', 'Borrowed', 'Repaid',
        'Liquidated', 'BadDebtWrittenOff', 'CollateralSet',
        'InsufficientLiquidity', 'InsufficientCollateral', 'ZeroPrice', 'ActionPaused']


# ストレージスロットの地図(設計文書2節、LayoutTestが見る)。ABIにない持ち分・停止ビットはスロットとして読む
SLOT_CONFIG, SLOT_RESERVES, SLOT_POSITIONS = 1, 2, 3


def _map(key_hex, slot):
    return int.from_bytes(keccak(bytes.fromhex(key_hex.lower().replace('0x', '').rjust(64, '0')) + slot.to_bytes(32, 'big')), 'big')


def slot_config(asset):
    """assetConfig[asset] +0: feed(0~19)·decimals(20)·collateralRatio(21)·pausedBits(22)·listed(23)"""
    return hex(_map(asset, SLOT_CONFIG))


def slot_reserve(asset, k):
    """reserves[asset] +k: 0 scaledDeposits, 1 scaledBorrows, 2 supplyIndex, 3 borrowIndex, 4 lastAccrual"""
    return hex(_map(asset, SLOT_RESERVES) + k)


def slot_position(asset, user, k):
    """positions[asset][user] +k: 0 scaledDeposit, 1 scaledDebt, 2 useAsCollateral"""
    inner = _map(asset, SLOT_POSITIONS)
    return hex(_map(user, inner) + k)


def h(sig):
    return '0x' + keccak(sig.encode()).hex()


def _sig(item):
    def t(p):
        if p['type'].startswith('tuple'):
            return '(' + ','.join(t(c) for c in p['components']) + ')' + p['type'][5:]
        return p['type']
    return '%s(%s)' % (item['name'], ','.join(t(p) for p in item.get('inputs', [])))


def load(path=ABI):
    with open(path, encoding='utf-8') as f:
        items = json.load(f)
    fn, ev, err, sigs = {}, {}, {}, {}
    for it in items:
        if it['type'] not in ('function', 'event', 'error'):
            continue
        s = _sig(it)
        sigs[it['name']] = s
        if it['type'] == 'function':
            fn[it['name']] = h(s)[:10]
        elif it['type'] == 'event':
            ev[it['name']] = h(s)
        else:
            err[h(s)[:10]] = s
    for s in OUTSIDE_FN:
        fn.setdefault(s, h(s)[:10])
    for s in OUTSIDE_EV:
        ev[s.split('(')[0]] = h(s)
    for s in OUTSIDE_ERR:
        err[h(s)[:10]] = s
    names = {v: k for k, v in fn.items()}
    return {'fn': fn, 'ev': ev, 'err': err, 'sig': sigs, 'name': names}


def check():
    t = load()
    have = set(t['fn']) | set(t['ev']) | {s.split('(')[0] for s in t['err'].values()}
    miss = [n for n in USED if n not in have]
    for n in USED:
        v = t['fn'].get(n) or t['ev'].get(n, '')[:10] or next((k for k, s in t['err'].items() if s.startswith(n + '(')), '')
        print('%-24s %s' % (n, v))
    if miss:
        print('ABIファイルにない: ' + ', '.join(miss))
        return 1
    print('運用ツールが使う名前 %d 個がabi/IMarket.jsonに全部ある' % len(USED))
    return 0


if __name__ == '__main__':
    sys.exit(check() if '--check' in sys.argv else 0)
