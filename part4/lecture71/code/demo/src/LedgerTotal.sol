// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract LedgerTotal {
    mapping(address user => uint256 amount) public deposits;
    uint256 public totalDeposits;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 amount) external {
        deposits[msg.sender] -= amount;
        totalDeposits -= amount;
        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "send failed");
    }
}
