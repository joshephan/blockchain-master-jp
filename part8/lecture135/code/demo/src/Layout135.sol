// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct S2 {
    int32 x;
    bool y;
}

// ドキュメントの例Cと同じ宣言(A、Bを展開して記述)。値を埋める関数だけを追加
contract CFill layout at 42 {
    uint a;
    uint128 transient b;
    uint8[] e;
    mapping(uint => S2) f;
    uint16 g;
    uint16 h;
    bytes16 transient i;
    S2 s;
    int8 k;
    bytes21 l;
    uint8[10] m;
    bytes5[8] n;
    bytes5 o;

    function fill() external returns (uint256 tb, uint256 ti) {
        a = type(uint256).max;
        e.push(0xee);
        f[1] = S2(-1, true);
        g = 0x1111;
        h = 0x2222;
        s = S2(0x33333333, true);
        k = -2;
        l = bytes21(0x555555555555555555555555555555555555555555);
        for (uint j = 0; j < 10; j++) m[j] = uint8(0x60 + j);
        for (uint j = 0; j < 8; j++) n[j] = bytes5(uint40(0x7070707000 + j));
        o = 0x8888888888;
        b = 0xbbbb;
        i = 0x99999999999999999999999999999999;
        assembly {
            tb := tload(0)
            ti := tload(0)
        }
    }
}

contract Order1 { uint128 a; uint256 b; uint128 c; }
contract Order2 { uint128 a; uint128 c; uint256 b; }
contract NoBackfill { uint8 a; uint256 b; uint8 c; }

contract Packed { uint128 public a; uint128 public b; function setA(uint128 x) external { a = x; } function setBoth(uint128 x, uint128 y) external { a = x; b = y; } }
contract Wide { uint256 public a; uint256 public b; function setA(uint256 x) external { a = x; } function setBoth(uint256 x, uint256 y) external { a = x; b = y; } }

// ドキュメントのマッピングの例そのまま
contract DocData {
    struct S { uint16 a; uint16 b; uint256 c; }
    uint x;
    mapping(uint => mapping(uint => S)) data;
    function put() external { data[4][9].c = 77; data[4][9].a = 1; data[4][9].b = 2; }
}

contract StrKey {
    uint x;
    mapping(string => uint) m;
    function put() external { m["abc"] = 5; }
}

contract Nested24 {
    uint24[][] x;
    function put() external {
        x.push(); x.push();
        for (uint j = 0; j < 12; j++) x[1].push(uint24(0x100000 + j));
    }
    function get(uint i, uint j) external view returns (uint24) { return x[i][j]; }
}

contract Str135 {
    string s31;
    string s32;
    function put() external {
        s31 = "0123456789012345678901234567890";
        s32 = "01234567890123456789012345678901";
    }
}

contract BadStr {
    string s;
    function poke(uint256 v) external { assembly { sstore(s.slot, v) } }
    function len() external view returns (uint256) { return bytes(s).length; }
    function read() external view returns (string memory) { return s; }
}
