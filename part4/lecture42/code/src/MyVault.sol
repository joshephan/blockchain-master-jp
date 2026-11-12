// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyVault is Ownable {
    constructor() Ownable(msg.sender) {}
}
