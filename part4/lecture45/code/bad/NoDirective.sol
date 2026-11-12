// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Deposit vault
/// @notice Everything you send becomes your balance.
contract Vault {
    // 取り分けておいた金額の合計
    uint256 public collected;
    mapping(address => uint256) public balanceOf;

    /// @notice Deposit ether. No fee.
    /// @dev Balance is recorded in balanceOf.
    /// @param minAmount Minimum amount to be credited
    /// @return credited Amount added to the balance
    function deposit(uint256 minAmount) external payable returns (uint256 credited) {
        uint256 fee=msg.value/100;
        collected += fee;
        credited = msg.value - fee;
        require(credited >= minAmount);
        balanceOf[msg.sender] += credited;
    }

    /// @notice Withdraw your whole balance.
    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok);
    }
}
