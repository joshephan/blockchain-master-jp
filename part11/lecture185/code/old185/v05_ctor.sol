// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.24;
contract Vault { address owner; function Vault() public { owner = msg.sender; } }
