// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P {
    uint256 public total;
    function f() public view virtual returns (uint256) { return total; }
    // view関数の中でfを呼ぶ
    function read() external view returns (uint256) { return f(); }
}
contract C is P {
    function f() public override returns (uint256) {
        total += 1;
        return total;
    }
}
