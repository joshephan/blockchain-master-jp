// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

abstract contract BalancesBase {
    mapping(address => uint256) balances;

    function move(address from, address to, uint amount) internal virtual {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}
