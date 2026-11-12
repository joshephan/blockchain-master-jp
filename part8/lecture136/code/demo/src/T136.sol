// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメントの例そのまま
contract MulService {
    uint transient multiplier;
    function setMultiplier(uint mul) external {
        multiplier = mul;
    }

    function multiply(uint value) external view returns (uint) {
        return value * multiplier;
    }
}

contract Batch {
    event Got(uint a, uint b);
    function run(MulService m) external returns (uint a, uint b) {
        m.setMultiplier(42);
        a = m.multiply(1);
        b = m.multiply(2);
        emit Got(a, b);
    }
}

contract Life {
    uint public stored;
    uint transient t;
    event Seen(uint stored, uint t);
    function bump() external {
        stored += 1;
        t += 1;
        emit Seen(stored, t);
    }
    function bumpTwice() external {
        this.bump();
        this.bump();
    }
    function readT() external view returns (uint) { return t; }
}

contract Same {
    uint public s0;
    uint transient t0;
    function both() external returns (uint sv, uint tv) {
        s0 = 11;
        t0 = 22;
        assembly {
            sv := sload(0)
            tv := tload(0)
        }
    }
}

contract Rev {
    uint transient t;
    uint public s;
    event R(uint t, uint s, bool ok);
    function inner(bool fail) external {
        t = 2;
        s = 2;
        if (fail) revert("no");
    }
    function run(bool fail) external {
        t = 1;
        s = 1;
        bool ok = true;
        try this.inner(fail) {} catch { ok = false; }
        emit R(t, s, ok);
    }
}

contract Other {
    function peek() external view returns (uint v) { assembly { v := tload(0) } }
}

library TLib {
    function put(uint v) internal { assembly { tstore(0, v) } }
}

contract TWriter {
    function put(uint v) external { assembly { tstore(0, v) } }
    function get() external view returns (uint v) { assembly { v := tload(0) } }
}

contract Share {
    uint transient t;
    event S(uint self, uint other, uint memLen);
    function readSelf() external view returns (uint) { return t; }
    function memLen() external pure returns (uint m) { assembly { m := mload(0x40) } }
    function run(Other o) external {
        t = 5;
        bytes memory big = new bytes(500);
        big[0] = 0x01;
        emit S(this.readSelf(), o.peek(), this.memLen());
    }
    function viaLib(TWriter w) external returns (uint a, uint b, uint c, uint d) {
        TLib.put(9);
        a = t;
        (bool ok, ) = address(w).delegatecall(abi.encodeCall(TWriter.put, (10)));
        require(ok);
        b = t;
        w.put(11);
        c = t;
        d = w.get();
    }
}

contract Static {
    uint transient t;
    function write() external { t = 3; }
    function read() external view returns (uint) { return t; }
    function tryStatic() external returns (bool okWrite, bool okRead) {
        (okWrite, ) = address(this).staticcall(abi.encodeCall(this.write, ()));
        (okRead, ) = address(this).staticcall(abi.encodeCall(this.read, ()));
    }
}

contract FlagS {
    bool busy;
    uint public n;
    function work() external {
        require(!busy);
        busy = true;
        n += 1;
        busy = false;
    }
}

contract FlagT {
    bool transient busy;
    uint public n;
    function work() external {
        require(!busy);
        busy = true;
        n += 1;
        busy = false;
    }
}

contract Leave {
    bool transient busy;
    uint public n;
    function work() external {
        require(!busy, "busy");
        busy = true;
        n += 1;
    }
    function twice() external {
        this.work();
        this.work();
    }
}

contract Asm136 {
    function put(uint v) external { assembly { tstore(1, v) } }
}
