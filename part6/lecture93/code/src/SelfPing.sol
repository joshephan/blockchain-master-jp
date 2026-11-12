// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SelfPing {
    constructor() {
        this.ping();
    }

    function ping() external pure {}
}
