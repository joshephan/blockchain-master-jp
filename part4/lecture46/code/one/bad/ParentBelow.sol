// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TokenInh is BalancesBase {
    function transfer(address to, uint amount) external returns (bool) {
        move(msg.sender, to, amount);
        return true;
    }
}

abstract contract BalancesBase {
    mapping(address => uint256) balances;

    function move(address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        balances[from] -= amount;
        balances[to] += amount;
    }
}
