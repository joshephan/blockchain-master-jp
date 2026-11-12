// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct S {
    uint a;
    uint b;
    uint8 c;
    uint8 d;
}

contract Mem137 {
    S stored;
    uint8[4] storedArr;
    event E(uint x, uint y, uint z);

    function fp() internal pure returns (uint p) { assembly { p := mload(0x40) } }

    function sizes() external pure returns (uint fixed8, uint dyn8, uint dynB1, uint bts, uint str, uint st, uint start) {
        start = fp();
        uint p = fp(); uint8[4] memory a; a[0] = 1; fixed8 = fp() - p;
        p = fp(); uint8[] memory b = new uint8[](4); b[0] = 1; dyn8 = fp() - p;
        p = fp(); bytes1[] memory c = new bytes1[](4); c[0] = 0x01; dynB1 = fp() - p;
        p = fp(); bytes memory d = new bytes(4); d[0] = 0x01; bts = fp() - p;
        p = fp(); string memory e = "abc"; bytes(e); str = fp() - p;
        p = fp(); S memory s; s.c = 1; st = fp() - p;
    }

    function words(uint from, uint n) internal pure returns (bytes32[] memory out) {
        bytes32[] memory tmp = new bytes32[](n);
        for (uint i = 0; i < n; i++) {
            bytes32 w;
            assembly { w := mload(add(from, mul(i, 32))) }
            tmp[i] = w;
        }
        out = tmp;
    }

    function nested() external pure returns (uint at, bytes32[] memory dump) {
        uint[][] memory x = new uint[][](2);
        x[0] = new uint[](1);
        x[1] = new uint[](2);
        x[0][0] = 0xa0;
        x[1][0] = 0xb0;
        x[1][1] = 0xb1;
        assembly { at := x }
        dump = words(at, 12);
    }

    function front() external pure returns (bytes32[] memory dump) {
        dump = words(0, 4);
    }

    function alloc() internal pure returns (uint[] memory r) { r = new uint[](10); }

    function neverFreed() external pure returns (uint p0, uint p1, uint p2, uint p3) {
        p0 = fp(); alloc(); p1 = fp(); alloc(); p2 = fp(); alloc(); p3 = fp();
    }

    function afterEmit(uint x) external returns (uint before, uint aft, bytes32 at0, bytes32 at1) {
        before = fp();
        emit E(x, x + 1, x + 2);
        aft = fp();
        assembly {
            at0 := mload(aft)
            at1 := mload(add(aft, 32))
        }
    }

    function expand(uint n) external view returns (uint used) {
        uint g = gasleft();
        bytes memory b = new bytes(n);
        b[0] = 0x01;
        used = g - gasleft();
    }

    function fresh() external pure returns (uint p) { p = fp(); }
}
