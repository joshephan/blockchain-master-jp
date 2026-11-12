// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IWETHWrong {
    function deposit() external payable returns (bool);
}

contract Jar {
    IWETHWrong public immutable weth;

    constructor(address weth_) {
        weth = IWETHWrong(weth_);
    }

    function wrap() external payable {
        bool ok = weth.deposit{value: msg.value}();
        require(ok, "deposit failed");
    }
}
