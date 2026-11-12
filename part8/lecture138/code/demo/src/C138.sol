// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract C138 {
    enum Color { Red, Green, Blue }

    function take(uint8 a, bool b, address c, int8 d) external pure returns (uint8, bool, address, int8) {
        return (a, b, c, d);
    }

    function color(Color x) external pure returns (uint8) { return uint8(x); }

    function dyn(uint[] calldata xs, bytes calldata bs) external pure returns (uint xo, uint xl, uint bo, uint bl, uint sum) {
        xo = getOffset(xs); xl = xs.length; bo = bsOffset(bs); bl = bs.length;
        for (uint i = 0; i < xs.length; i++) sum += xs[i];
    }
    function getOffset(uint[] calldata xs) internal pure returns (uint o) { assembly { o := xs.offset } }
    function bsOffset(bytes calldata bs) internal pure returns (uint o) { assembly { o := bs.offset } }

    function size() external pure returns (uint) { return msg.data.length; }

    // アセンブリで上位ビットを残した値
    function dirtyU8() external pure returns (uint8 x, bool eq, uint256 widened, uint256 raw) {
        assembly { x := 0x1ff }
        eq = (x == 0xff);
        widened = uint256(x);
        assembly { raw := x }
    }
    function dirtyBool() external pure returns (bool b, bool cond, bool eqTrue, uint256 raw) {
        assembly { b := 2 }
        if (b) cond = true;
        eqTrue = (b == true);
        assembly { raw := b }
    }
    function dirtyI8() external pure returns (int8 d, int256 widened) {
        assembly { d := 0xff }
        widened = int256(d);
    }
    function dirtyEnum() external pure returns (uint8) {
        Color c;
        assembly { c := 5 }
        return uint8(c);
    }
    function dirtyEnumRet() external pure returns (Color c) {
        assembly { c := 5 }
    }
    mapping(uint8 => uint) public m;
    function dirtyKey() external returns (uint256 slotDirty, uint256 slotClean) {
        uint8 k;
        assembly { k := 0x101 }
        m[k] = 7;
        slotDirty = m[1];
        slotClean = m[k];
    }
}
