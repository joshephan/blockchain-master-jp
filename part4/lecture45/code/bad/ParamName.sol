// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ParamName {
    /// @notice Deposit ether.
    /// @param minAmout Minimum amount to be credited
    function deposit(uint256 minAmount) external payable returns (uint256) {
        return minAmount;
    }
}
