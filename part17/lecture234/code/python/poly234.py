# 第234講のデモ: 大きな計算をやり直さずランダムな一点で確認する
# 標準ライブラリだけを使う。結果はout\poly234.txt
import random, time

P = 21888242871839275222246405745257275088548364400416034343698204186575808495617  # alt_bn128の群の位数(素数)
rng = random.Random(234)

def mul_naive(a, b):
    out = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        if x == 0:
            continue
        for j, y in enumerate(b):
            out[i + j] = (out[i + j] + x * y) % P
    return out

def ev(poly, r):
    acc = 0
    for c in reversed(poly):
        acc = (acc * r + c) % P
    return acc

print("[1] 小さな算数: x^3 + x + 5 = 35")
for x in range(0, 6):
    print("  x =", x, "->", x**3 + x + 5)
print("  段階に展開(x=3): t1 = x*x =", 3*3, "/ t2 = t1*x =", 9*3, "/ t3 = t2 + x =", 27+3, "/ out = t3 + 5 =", 30+5)

for n in (1000, 2000):
    a = [rng.randrange(P) for _ in range(n)]
    b = [rng.randrange(P) for _ in range(n)]
    t0 = time.perf_counter(); c = mul_naive(a, b); t1 = time.perf_counter()
    print(f"\n[2] 次数{n-1}の多項式二つの積 C = A*B (係数{len(c)}個)")
    print(f"  掛け直して確認: {t1-t0:.3f}秒 (掛け算 {n*n:,}回)")
    r = rng.randrange(P)
    t0 = time.perf_counter(); ok = ev(c, r) == ev(a, r) * ev(b, r) % P; t1 = time.perf_counter()
    print(f"  ランダムな一点rでC(r) == A(r)*B(r): {ok}, {t1-t0:.4f}秒 (掛け算 約{len(a)+len(b)+len(c):,}回)")
    bad = list(c); k = rng.randrange(len(bad)); bad[k] = (bad[k] + 1) % P
    caught = sum(1 for _ in range(1000) if ev(bad, (rr := rng.randrange(P))) != ev(a, rr) * ev(b, rr) % P)
    print(f"  係数一つ({k}番目)を1だけ変えたC': ランダムな点1000回のうち引っかかった回数 {caught}")
    print(f"  二つの多項式が違えば同じ値が出る点は多くても{len(c)-1}個、選べる点は約2^{P.bit_length()-1}個")
