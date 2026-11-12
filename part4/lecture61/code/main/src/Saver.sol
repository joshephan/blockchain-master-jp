// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Saver {
    function (uint256) external returns (bool) public cb;

    function save(function (uint256) external returns (bool) f) external {
        cb = f;
    }
}

contract Target {
    function check(uint256 x) external pure returns (bool) {
        return x > 0;
    }
}
