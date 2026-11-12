"""Marketの運用ツール2: RPC一つがくれたMarketの帳簿の値をブロックハッシュ一つに照らして確認。

使い方: python -I ops/market_verify.py <Marketのアドレス> <資産のアドレス> <RPC> <信頼するブロックハッシュ>
- 信頼するブロックハッシュ: このツールの外で決める(自分のノード、複数のRPCが一致したfinalizedブロックなど)。ツールはそのハッシュを確認しない
- 確認三つ: 1) RPCがくれたブロックヘッダーのkeccakが信頼するハッシュと同じ 2) eth_getProofの証明がヘッダーのステートルートまでつながる
  3) 証明で取り出したtotalDeposits[資産]がeth_callの答えと同じ
- 一つでもずれるか、RPCがそのブロックを知らなければ終了コード1
- 読み取りのリクエストだけを送る。署名・送信なし
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from market_read import rpc, SELECTORS  # noqa: E402
from mpt import header_hash, keccak, verify_account, verify_storage  # noqa: E402

TOTAL_DEPOSITS_SLOT = 4  # スロットマップ: mapping(address => Amount) totalDeposits


def deposits_slot(asset):
    key = bytes.fromhex(asset[2:].lower().rjust(64, '0')) + TOTAL_DEPOSITS_SLOT.to_bytes(32, 'big')
    return '0x' + keccak(key).hex()


def main(argv):
    market, asset, url, trusted = argv[0], argv[1], argv[2], argv[3]
    at = {'blockHash': trusted}
    r = rpc(url, 'eth_getBlockByHash', [trusted, False])
    head = r.get('result')
    if not head:
        why = json.dumps(r['error'], ensure_ascii=False) if 'error' in r else 'このRPCにそのハッシュのブロックなし'
        print(f'1) ブロックヘッダー: 不明 ({why})')
        return 1
    ok_head = '0x' + header_hash(head).hex() == trusted
    print(f'1) ブロックヘッダーのハッシュ: {"同じ" if ok_head else "違う"} (ブロック {int(head["number"], 16)}、ステートルート {head["stateRoot"][:14]}…)')
    if not ok_head:
        return 1
    slot = deposits_slot(asset)
    pr = rpc(url, 'eth_getProof', [market, [slot], at])
    if 'result' not in pr:
        print(f'2) 証明: 受け取れず ({json.dumps(pr.get("error"), ensure_ascii=False)})')
        return 1
    pr = pr['result']
    try:
        acc = verify_account(head['stateRoot'], market, pr)
        proven = verify_storage(acc['storageHash'], slot, pr['storageProof'][0]['proof'])
    except (ValueError, TypeError) as e:
        print(f'2) 証明: 失敗 ({e})')
        return 1
    print(f'2) 証明: ステートルートまでつながる (アカウントノード {len(pr["accountProof"])}個、ストレージスロットのノード {len(pr["storageProof"][0]["proof"])}個)')
    c = rpc(url, 'eth_call', [{'to': market, 'data': SELECTORS['totalDeposits(address)'] + asset[2:].lower().rjust(64, '0')}, at])
    called = int(c['result'], 16) if 'result' in c else None
    same = called == proven
    print(f'3) totalDeposits: 証明の値 {proven}、eth_callの答え {called} -> {"同じ" if same else "違う"}')
    print('結果:', '確認済み' if same else 'ずれ')
    return 0 if same else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
