// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IWETH {
    function deposit() external payable;
}

contract Jar {
    IWETH public immutable weth;

    constructor(address weth_) {
        weth = IWETH(weth_);
    }

    function wrap() external payable {
        weth.deposit{value: msg.value}();
    }
}
