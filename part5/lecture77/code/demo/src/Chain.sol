// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract C {
    address public lastSender;
    address public lastOrigin;

    function hit() external returns (address sender, address origin) {
        lastSender = msg.sender;
        lastOrigin = tx.origin;
        return (msg.sender, tx.origin);
    }
}

contract B {
    C public c;

    constructor(C _c) {
        c = _c;
    }

    function hit() external returns (address, address) {
        return c.hit();
    }
}

contract A {
    B public b;

    constructor(B _b) {
        b = _b;
    }

    function hit() external returns (address, address) {
        return b.hit();
    }
}
