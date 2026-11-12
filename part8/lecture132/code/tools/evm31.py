"""第31章の共用関数: バイトコードの命令分割、ソースマップの展開、バイト位置 -> 行番号、メタデータの末尾の読み取り"""
import os, subprocess, json, re

HOME = os.path.expanduser('~')
S8 = os.path.join(os.environ['APPDATA'], 'svm', '0.8.30', 'solc-0.8.30')
FORGE = HOME + r'\.foundry\bin\forge.exe'
CAST = HOME + r'\.foundry\bin\cast.exe'
ANVIL = HOME + r'\.foundry\bin\anvil.exe'


def instructions(code: bytes):
    """[(pc, opcode, pushデータbytes)] 先頭から読む。PUSH1~PUSH32(0x60~0x7f)は後ろの1~32バイトを連れていく"""
    out = []; pc = 0
    while pc < len(code):
        op = code[pc]
        n = op - 0x5f if 0x60 <= op <= 0x7f else 0
        out.append((pc, op, code[pc + 1:pc + 1 + n]))
        pc += 1 + n
    return out


def decompress(sm: str):
    """s:l:f:j:mの一覧。空欄は前の値、':'が欠けると後ろの欄はすべて前の値"""
    res = []; prev = ['', '', '', '', '']
    for ent in sm.split(';'):
        parts = ent.split(':') if ent != '' else []
        cur = list(prev)
        for i, p in enumerate(parts):
            if p != '':
                cur[i] = p
        res.append(cur); prev = cur
    return [(int(a), int(b), int(c), d, int(e) if e != '' else 0) for a, b, c, d, e in res]


def line_col(src_bytes: bytes, off: int):
    """バイト位置 -> (行, 桁)。行と桁は1から、桁はその行の中の文字数"""
    before = src_bytes[:off]
    line = before.count(b'\n') + 1
    col = len(before[before.rfind(b'\n') + 1:].decode('utf8', 'replace')) + 1
    return line, col


def cbor_tail(code: bytes):
    n = int.from_bytes(code[-2:], 'big')
    return n, code[-2 - n:-2]


def opname_table():
    """cast disassembleで0x00~0xffの名札を作る(PUSHデータなしで1バイトずつ)"""
    names = {}
    for b in range(256):
        if 0x60 <= b <= 0x7f:
            names[b] = f'PUSH{b - 0x5f}'; continue
        r = subprocess.run([CAST, 'disassemble', '0x%02x' % b], capture_output=True, text=True).stdout.strip()
        m = re.match(r'[0-9a-f]+: (\S+)', r)
        names[b] = m.group(1) if m else 'INVALID'
    return names
