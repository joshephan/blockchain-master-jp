// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 原資産のトークン(デモ用)
contract Asset is ERC20 {
    constructor() ERC20("Asset", "AST") {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}

// OpenZeppelin Contracts 5.4.0のERC4626を継承しただけの金庫(デモ用、_decimalsOffset 0)
contract Vault is ERC4626 {
    constructor(IERC20 asset_) ERC20("Vault Share", "vAST") ERC4626(asset_) {}
}
