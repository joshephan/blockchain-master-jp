// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Target {
    uint256 public count;

    // 引数xだけを受け取る。値とガスは引数にない
    function hit(uint256 x) external payable returns (uint256 got, uint256 value, uint256 gas) {
        return (x, msg.value, gasleft());
    }

    // ストレージに一回書き込む
    function bump() external {
        count += 1;
    }
}

contract Opt {
    Target public t;

    constructor(Target _t) payable {
        t = _t;
    }

    function plain() external returns (uint256, uint256, uint256) {
        return t.hit(3);
    }

    function withOptions() external returns (uint256, uint256, uint256) {
        return t.hit{value: 7, gas: 50000}(3);
    }

    function withGas() external returns (uint256, uint256, uint256) {
        return t.hit{gas: 50000}(3);
    }

    function named() external returns (uint256, uint256, uint256) {
        return t.hit{value: 7}({x: 3});
    }

    function bumpLimited() external {
        t.bump{gas: 5000}();
    }

    function bumpFull() external {
        t.bump();
    }
}
