// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメントのWithdrawalContractで足す行一つだけをuncheckedで囲んだ版
contract WithdrawalUnchecked {
    address public richest;
    uint256 public mostSent;

    mapping(address => uint256) pendingWithdrawals;

    error NotEnoughEther();

    constructor() payable {
        richest = msg.sender;
        mostSent = msg.value;
    }

    function becomeRichest() public payable {
        if (msg.value <= mostSent) revert NotEnoughEther();
        unchecked {
            pendingWithdrawals[richest] += msg.value; // イーサの総量は2の256乗よりはるかに小さいのでオーバーフローしない
        }
        richest = msg.sender;
        mostSent = msg.value;
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success);
    }
}
