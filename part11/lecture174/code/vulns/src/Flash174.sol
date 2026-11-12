// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IFlashBorrower {
    function onFlashLoan(uint256 amount) external;
}

// 第174講のトイの貸出プール。持っているBを一つのトランザクション内で貸し、同じトランザクションで返させる
// トークンの代わりに内部の帳簿(balanceB)だけで数える(最小の形)
contract ToyFlashLender {
    uint256 public balanceB;

    constructor(uint256 b) {
        balanceB = b;
    }

    // 全額を帳簿から引いて貸し、コールバックの後に返したかを確認
    function flashLoan(uint256 amount) external {
        if (amount > balanceB) revert NotEnough();
        uint256 before = balanceB;
        borrowed[msg.sender] += amount;
        balanceB -= amount;
        IFlashBorrower(msg.sender).onFlashLoan(amount);
        if (balanceB < before) revert NotRepaid();
    }

    // 借りた側がコールバックの中で返す
    function repay(uint256 amount) external {
        borrowed[msg.sender] -= amount;
        balanceB += amount;
    }

    mapping(address => uint256) public borrowed;

    error NotEnough();
    error NotRepaid();
}
