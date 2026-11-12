// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {SimpleToken, ToyOracle} from "./Toys.sol";

// 講義用の暗号資産担保型。担保トークン(COL)を金庫に預け、その値の150%の範囲でVUSDを発行する
// 清算の関数なし
contract VaultUSD {
    uint256 public constant MIN_RATIO_PCT = 150;

    SimpleToken public immutable col;
    SimpleToken public immutable vusd;
    ToyOracle public immutable oracle;

    mapping(address => uint256) public collateralOf;
    mapping(address => uint256) public debtOf;

    error Undercollateralized(uint256 valueUsd, uint256 debtUsd);

    constructor(SimpleToken col_, ToyOracle oracle_) {
        col = col_;
        oracle = oracle_;
        vusd = new SimpleToken("Vault USD", address(this));
    }

    function deposit(uint256 amount) external {
        collateralOf[msg.sender] += amount;
        col.transferFrom(msg.sender, address(this), amount);
    }

    function mint(uint256 amount) external {
        debtOf[msg.sender] += amount;
        _checkRatio(msg.sender);
        vusd.mint(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        vusd.burn(msg.sender, amount);
        debtOf[msg.sender] -= amount;
    }

    function withdraw(uint256 amount) external {
        collateralOf[msg.sender] -= amount;
        _checkRatio(msg.sender);
        col.transfer(msg.sender, amount);
    }

    // 担保のドル建ての値(1e18単位)
    function valueOf(address user) public view returns (uint256) {
        return collateralOf[user] * oracle.settledPrice() / 1e18;
    }

    function isSafe(address user) public view returns (bool) {
        return valueOf(user) * 100 >= debtOf[user] * MIN_RATIO_PCT;
    }

    function _checkRatio(address user) internal view {
        if (!isSafe(user)) revert Undercollateralized(valueOf(user), debtOf[user]);
    }
}
