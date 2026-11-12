// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Vault {
    function pay() external payable returns (uint256 bal, uint256 val) {
        bal = address(this).balance;
        val = msg.value;
    }
}
