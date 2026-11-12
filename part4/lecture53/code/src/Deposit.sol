// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Deposit {
    uint256 public amount;

    function put() external payable {
        amount = msg.value;
    }
}
