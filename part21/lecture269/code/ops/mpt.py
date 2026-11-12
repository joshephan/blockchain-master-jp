"""Marketの運用ツール2の部品: keccak-256、RLP、ブロックヘッダーのハッシュ、マークル・パトリシア・トライの証明の確認。標準ライブラリだけを使う(keccakの値はcast keccakと照合した)。"""

# keccak-256 (元のKeccak、SHA3のパディングではない)
_RC = [0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000, 0x000000000000808B,
       0x0000000080000001, 0x8000000080008081, 0x8000000000008009, 0x000000000000008A, 0x0000000000000088,
       0x0000000080008009, 0x000000008000000A, 0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
       0x8000000000008003, 0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
       0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008]
_ROT = [[0, 36, 3, 41, 18], [1, 44, 10, 45, 2], [62, 6, 43, 15, 61], [28, 55, 25, 21, 56], [27, 20, 39, 8, 14]]
_M = (1 << 64) - 1


def _rol(x, n):
    n %= 64
    return ((x << n) | (x >> (64 - n))) & _M


def _f(A):
    for rc in _RC:
        C = [A[x][0] ^ A[x][1] ^ A[x][2] ^ A[x][3] ^ A[x][4] for x in range(5)]
        D = [C[(x - 1) % 5] ^ _rol(C[(x + 1) % 5], 1) for x in range(5)]
        A = [[A[x][y] ^ D[x] for y in range(5)] for x in range(5)]
        B = [[0] * 5 for _ in range(5)]
        for x in range(5):
            for y in range(5):
                B[y][(2 * x + 3 * y) % 5] = _rol(A[x][y], _ROT[x][y])
        A = [[B[x][y] ^ ((~B[(x + 1) % 5][y]) & B[(x + 2) % 5][y]) for y in range(5)] for x in range(5)]
        A[0][0] ^= rc
    return A


def keccak(data: bytes) -> bytes:
    rate = 136
    p = bytearray(data) + b'\x01'
    while len(p) % rate:
        p += b'\x00'
    p[-1] |= 0x80
    A = [[0] * 5 for _ in range(5)]
    for off in range(0, len(p), rate):
        blk = p[off:off + rate]
        for i in range(rate // 8):
            x, y = i % 5, i // 5
            A[x][y] ^= int.from_bytes(blk[8 * i:8 * i + 8], 'little')
        A = _f(A)
    out = b''
    for i in range(4):
        x, y = i % 5, i // 5
        out += A[x][y].to_bytes(8, 'little')
    return out


# RLP
def rlp_enc(x):
    if isinstance(x, (bytes, bytearray)):
        if len(x) == 1 and x[0] < 0x80:
            return bytes(x)
        return _len(len(x), 0x80) + bytes(x)
    body = b''.join(rlp_enc(i) for i in x)
    return _len(len(body), 0xc0) + body


def _len(n, off):
    if n < 56:
        return bytes([off + n])
    b = n.to_bytes((n.bit_length() + 7) // 8, 'big')
    return bytes([off + 55 + len(b)]) + b


def rlp_dec(b):
    item, rest = _dec(b)
    assert rest == b''
    return item


def _dec(b):
    p = b[0]
    if p < 0x80:
        return b[:1], b[1:]
    if p < 0xb8:
        n = p - 0x80
        return b[1:1 + n], b[1 + n:]
    if p < 0xc0:
        ll = p - 0xb7
        n = int.from_bytes(b[1:1 + ll], 'big')
        return b[1 + ll:1 + ll + n], b[1 + ll + n:]
    if p < 0xf8:
        n = p - 0xc0
        body, rest = b[1:1 + n], b[1 + n:]
    else:
        ll = p - 0xf7
        n = int.from_bytes(b[1:1 + ll], 'big')
        body, rest = b[1 + ll:1 + ll + n], b[1 + ll + n:]
    out = []
    while body:
        it, body = _dec(body)
        out.append(it)
    return out, rest


def hb(h):
    h = h[2:] if h.startswith('0x') else h
    if len(h) % 2:
        h = '0' + h
    return bytes.fromhex(h)


def qty(h):
    v = int(h, 16)
    return v.to_bytes((v.bit_length() + 7) // 8, 'big') if v else b''


# ヘッダーの欄の順番(イエローペーパー + ロンドン・上海・カンクン・プラハで足した欄、最後の二つの欄はまだないチェーンが多い)。応答にある欄だけを順に入れる
HEADER_FIELDS = [('parentHash', 'b'), ('sha3Uncles', 'b'), ('miner', 'b'), ('stateRoot', 'b'), ('transactionsRoot', 'b'),
                 ('receiptsRoot', 'b'), ('logsBloom', 'b'), ('difficulty', 'q'), ('number', 'q'), ('gasLimit', 'q'),
                 ('gasUsed', 'q'), ('timestamp', 'q'), ('extraData', 'b'), ('mixHash', 'b'), ('nonce', 'b'),
                 ('baseFeePerGas', 'q'), ('withdrawalsRoot', 'b'), ('blobGasUsed', 'q'), ('excessBlobGas', 'q'),
                 ('parentBeaconBlockRoot', 'b'), ('requestsHash', 'b'), ('blockAccessListHash', 'b'), ('slotNumber', 'q')]


def header_hash(blk):
    items = []
    for k, t in HEADER_FIELDS:
        if k in blk and blk[k] is not None:
            items.append(hb(blk[k]) if t == 'b' else qty(blk[k]))
    return keccak(rlp_enc(items))


def nibbles(b):
    out = []
    for x in b:
        out += [x >> 4, x & 15]
    return out


def mpt_get(root: bytes, key: bytes, proof_nodes):
    """証明ノードのリストでrootの下のkeyの値を探す。ノードのハッシュが合わなければValueError、キーがなければNone"""
    path = nibbles(keccak(key))
    want = root
    i = 0
    for raw in proof_nodes:
        raw = hb(raw)
        if keccak(raw) != want:
            raise ValueError('証明ノードのハッシュが上のノードが指す値と違う')
        node = rlp_dec(raw)
        while True:
            if len(node) == 17:
                if i == len(path):
                    return node[16] or None
                nxt = node[path[i]]
                i += 1
            elif len(node) == 2:
                enc = nibbles(node[0])
                flag = enc[0]
                rest = enc[2:] if flag in (0, 2) else enc[1:]
                if path[i:i + len(rest)] != rest:
                    return None
                i += len(rest)
                if flag in (2, 3):
                    return node[1]
                nxt = node[1]
            else:
                raise ValueError('ノードの形がおかしい')
            if isinstance(nxt, list):
                node = nxt
                continue
            if nxt == b'':
                return None
            want = nxt
            break
    raise ValueError('証明ノードが足りない')


def verify_account(state_root_hex, address_hex, proof):
    """eth_getProofの応答のaccountProofをstate_rootに照らしてアカウントの四つの欄を取り出す"""
    val = mpt_get(hb(state_root_hex), hb(address_hex), proof['accountProof'])
    if val is None:
        return None
    nonce, bal, sroot, chash = rlp_dec(val)
    acc = {'nonce': int.from_bytes(nonce, 'big'), 'balance': int.from_bytes(bal, 'big'),
           'storageHash': '0x' + sroot.hex(), 'codeHash': '0x' + chash.hex()}
    return acc


def verify_storage(storage_root_hex, slot_hex, nodes):
    val = mpt_get(hb(storage_root_hex), hb(slot_hex).rjust(32, b'\x00'), nodes)
    if val is None:
        return 0
    return int.from_bytes(rlp_dec(val), 'big')
