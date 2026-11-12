// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Vault {
    address public admin;
    uint256 public balanceAtStart;
    uint256 public valueAtStart;
    uint256 public codeLengthAtStart;

    constructor(address admin_) payable {
        balanceAtStart = address(this).balance;
        valueAtStart = msg.value;
        codeLengthAtStart = address(this).code.length;
        admin = admin_;
    }
}
