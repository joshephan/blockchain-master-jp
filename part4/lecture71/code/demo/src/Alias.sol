// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Alias {
    mapping(address => uint256) public deposits;

    function credit(address user, uint256 amount) external {
        mapping(address => uint256) storage m = deposits;
        m[user] += amount;
    }

    function creditTwice(address user, uint256 amount) external {
        add(deposits, user, amount);
        add(deposits, user, amount);
    }

    function add(mapping(address => uint256) storage m, address user, uint256 amount) internal {
        m[user] += amount;
    }
}
