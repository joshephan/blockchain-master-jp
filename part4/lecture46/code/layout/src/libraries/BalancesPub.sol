// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

library BalancesPub {
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) public {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}
