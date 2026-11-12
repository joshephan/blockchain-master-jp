// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// OpenZeppelin Contracts 5.4.0のERC20を継承しただけのトークン(デモ用)
contract OzToken is ERC20 {
    constructor(uint256 supply) ERC20("Oz Token", "OZT") {
        _mint(msg.sender, supply);
    }
}
