// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable as OwnableOld} from "./OwnableOld.sol";
import {Ownable} from "./OwnableNew.sol";

contract OldVault is OwnableOld {}
contract Vault is Ownable {}
