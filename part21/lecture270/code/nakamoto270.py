# 第270講のデモ: ナカモト係数をおもちゃのデータで計算する。標準ライブラリだけ
# 使い方: python -I -X utf8 nakamoto270.py [rpcアドレス]  (rpcを渡すとそのanvilでブロックヘッダーのminerの欄を数える)
import json, sys, urllib.request
from fractions import Fraction


def coefficient(shares, threshold, inclusive=False):
    """大きい方から足して持ち分がしきい値を超える(inclusiveなら同じか超える)のに必要な最小の主体の数"""
    total = sum(shares.values())
    acc = 0
    picked = []
    for name, v in sorted(shares.items(), key=lambda kv: -kv[1]):
        acc += v
        picked.append(name)
        f = Fraction(acc, total)
        if (f >= threshold) if inclusive else (f > threshold):
            return len(picked), picked, f
    return None, picked, Fraction(acc, total)


def group(shares, owner):
    out = {}
    for k, v in shares.items():
        o = owner.get(k, k)
        out[o] = out.get(o, 0) + v
    return out


def show(title, shares, rules):
    total = sum(shares.values())
    print(f"== {title} (合計 {total})")
    print("   " + ", ".join(f"{k} {v}" for k, v in sorted(shares.items(), key=lambda kv: -kv[1])))
    for label, th, inc in rules:
        n, picked, f = coefficient(shares, th, inc)
        print(f"   {label}: 係数 {n}  ({'+'.join(picked)} = {f.numerator}/{f.denominator} = {float(f):.3f})")


ONE_THIRD = ("1/3超(ファイナリティ停止)", Fraction(1, 3), False)
HALF = ("1/2超", Fraction(1, 2), False)
TWO_THIRDS = ("2/3以上(単独でファイナリティ)", Fraction(2, 3), True)

# 1. バリデーターの持ち分(おもちゃ、運営主体十二か所、合計100)
stake = {"A": 24, "B": 15, "C": 12, "D": 9, "E": 8, "F": 7, "G": 6, "H": 5, "I": 5, "J": 4, "K": 3, "L": 2}
show("バリデーターの持ち分、主体十二か所", stake, [ONE_THIRD, HALF, TWO_THIRDS])
# 2. 同じ主体にまとめる: BとEは同じオペレーター、G・H・Iは一か所が運営
owner = {"E": "B", "H": "G", "I": "G"}
show("同じオペレーターをまとめたあと", group(stake, owner), [ONE_THIRD, HALF, TWO_THIRDS])
# 3. アドレスで数えると: Aが持ち分をアドレス六つに分けておいた場合(アドレス数は増え、係数はそのまま)
split = {k: v for k, v in stake.items() if k != "A"}
for i in range(6):
    split[f"A{i+1}"] = 4
show("Aがアドレス六つに分けて見せると(アドレスで数える)", split, [ONE_THIRD])
show("その六つをAにまとめると", group(split, {f"A{i+1}": "A" for i in range(6)}), [ONE_THIRD])
# 4. クライアントの持ち分(おもちゃ、実行プログラム四つ)
client = {"X": 52, "Y": 25, "Z": 15, "W": 8}
show("クライアントの持ち分", client, [ONE_THIRD, TWO_THIRDS])
# 5. 代理人の票(おもちゃ、全供給量1000、委任された票450)
supply = 1000
deleg = {"d1": 160, "d2": 120, "d3": 90, "d4": 50, "d5": 30}
q = Fraction(4, 100)
n, picked, _ = coefficient({**deleg, "_委任なし": supply - sum(deleg.values())}, q, True)
print(f"== 代理人の票 (供給量 {supply}、委任された票 {sum(deleg.values())}、定足数4% = {int(supply*q)})")
print(f"   d1一人で {deleg['d1']} >= {int(supply*q)}: 定足数を一人で満たす")
votes = sum(deleg.values())
acc = 0
for i, (k, v) in enumerate(sorted(deleg.items(), key=lambda kv: -kv[1]), 1):
    acc += v
    if acc * 2 > votes:
        print(f"   委任された票の過半数({votes}の半分超): 代理人 {i}人 ({acc})")
        break

# 6. Marketの層ごとの係数(第269講の表から、キャップストーン末の版)。None = 変えたり止めたりする道がコードにない
layers = [
    ("コード", None, "デプロイ後に変える道なし(A-05)"),
    ("アップグレード", None, "プロキシなし、実装スロット0、新しい版は新しいアドレス"),
    ("管理者キー: 設定", 2, "署名者三人のうち二人 + タイムロック2日の公開待機、署名者三人が互いに別の主体のとき"),
    ("管理者キー: 停止", 1, "事前に承認した停止の提案は署名者一人、預け入れ・借り入れだけを止める(引き出しはふさがらない)"),
    ("価格", 1, "資産ごとに価格の出どころ一つ、変える関数なし"),
    ("トークン", 1, "上場したトークンごとに発行体(凍結する鍵があれば)"),
    ("接続", 1, "RPCを一つだけ使うなら(複数と照らし合わせればその数)"),
    ("チェーン", 1, "ローカルのanvil、ブロックを作る側は一つ"),
]
print("== Marketの層ごとの係数")
for name, n, note in layers:
    print(f"   {name}: {'-' if n is None else n}  ({note})")
nums = [n for _, n, _ in layers if n is not None]
print(f"   最も小さい値: {min(nums)}")
# 管理者キーの層を主体でまとめると: 署名者a・b・cのうちa・bを一か所が握れば設定も1
signers = {"a": 1, "b": 1, "c": 1}
for title, sh_ in (("署名者三人が互いに別の主体", signers), ("a・bを一か所が握ると", group(signers, {"b": "a"}))):
    n, picked, f = coefficient(sh_, Fraction(2, 3), True)
    print(f"   管理者キーの設定(三人のうち二人)、{title}: 係数 {n}  ({'+'.join(picked)})")

# 7. チェーンで数える: anvilのブロックヘッダーのminerの欄
if len(sys.argv) > 1:
    rpc = sys.argv[1]

    def call(method, params):
        req = urllib.request.Request(rpc, data=json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode(), headers={"Content-Type": "application/json"})
        return json.loads(urllib.request.urlopen(req).read())["result"]

    plan = [("0x00000000000000000000000000000000000000a1", 8), ("0x00000000000000000000000000000000000000b2", 5),
            ("0x00000000000000000000000000000000000000c3", 4), ("0x00000000000000000000000000000000000000d4", 3)]
    for addr, cnt in plan:
        call("anvil_setCoinbase", [addr])
        call("anvil_mine", [hex(cnt)])
    head = int(call("eth_blockNumber", []), 16)
    seen = {}
    for b in range(1, head + 1):
        m = call("eth_getBlockByNumber", [hex(b), False])["miner"].lower()
        seen[m] = seen.get(m, 0) + 1
    short = {k[-2:]: v for k, v in seen.items()}
    show(f"anvilのブロック1~{head}のminerの欄", short, [ONE_THIRD, HALF])
    show("a1とd4が同じ主体なら", group(short, {"d4": "a1"}), [ONE_THIRD, HALF])
