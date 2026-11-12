// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

abstract contract BalancesBase {
    mapping(address => uint256) balances;

    function move(address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        balances[from] -= amount;
        balances[to] += amount;
    }
}

contract TokenInh is BalancesBase {
    function move(address from, address to, uint amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
    }
}
