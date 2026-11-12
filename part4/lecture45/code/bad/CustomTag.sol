// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CustomTag {
    /// @notice Deposit ether.
    /// @custom:fee 1% goes to collected.
    function deposit() external payable {}
}
