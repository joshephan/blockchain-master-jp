// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第41講のドキュメントの例Tokenのapproveの行そのまま(0でなければ新しい値を拒否)。移す行はmoveを展開して書き、最初の発行量を与えるコンストラクタを追加(デモ用)
contract DocToken {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 supply) {
        balances[msg.sender] = supply;
    }

    function transfer(address to, uint256 amount) external returns (bool success) {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool success) {
        require(allowed[from][msg.sender] >= amount);
        allowed[from][msg.sender] -= amount;
        require(balances[from] >= amount);
        balances[from] -= amount;
        balances[to] += amount;
        return true;
    }

    function approve(address spender, uint256 tokens) external returns (bool success) {
        require(allowed[msg.sender][spender] == 0, "");
        allowed[msg.sender][spender] = tokens;
        return true;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }
}
