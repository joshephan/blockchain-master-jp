// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメントのIR-based Codegen Changesの例(名前だけ変更)
contract A {
    uint x;
    constructor() {
        x = 42;
    }
    function f() public view returns (uint256) {
        return x;
    }
}

contract B is A {
    uint public y = f();
}

contract Del {
    struct S {
        uint64 y;
        uint64 z;
    }
    S s;
    function fill() public {
        s = S(1, 2);
        assembly {
            let v := sload(s.slot)
            sstore(s.slot, or(v, shl(128, 0xabcd)))
        }
    }
    function clear() public {
        delete s;
    }
    function raw() public view returns (bytes32 r) {
        assembly {
            r := sload(s.slot)
        }
    }
}

contract Twice {
    function f(uint a) public pure mod() returns (uint r) {
        r = a++;
    }
    modifier mod() { _; _; }
}

contract Active {
    bool active = true;
    modifier mod() {
        _;
        active = false;
        _;
    }
    function foo() external mod() returns (uint ret) {
        if (active)
            ret = 1;
    }
}

contract Order {
    function preincr_u8(uint8 a) public pure returns (uint8) {
        return ++a + a;
    }
    function add(uint8 a, uint8 b) public pure returns (uint8) {
        return a + b;
    }
    function g(uint8 a, uint8 b) public pure returns (uint8) {
        return add(++a + ++b, a + b);
    }
    function m() public pure returns (uint256 aMod, uint256 mMod) {
        uint256 x = 3;
        aMod = addmod(++x, ++x, x);
        mMod = mulmod(++x, ++x, x);
    }
}

contract Clean {
    function f(uint8 a) public pure returns (uint r1, uint r2) {
        a = ~a;
        assembly {
            r1 := a
        }
        r2 = a;
    }
}

contract Big {
    function f() public pure {
        uint[] memory arr;
        uint n = (type(uint64).max - 0x80 - 31) / 32;
        arr = new uint[](n);
    }
}
