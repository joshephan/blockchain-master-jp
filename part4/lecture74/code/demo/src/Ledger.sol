// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract LedgerTotal {
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function clear(address user) external {
        totalDeposits -= deposits[user];
        delete deposits[user];
    }
}
