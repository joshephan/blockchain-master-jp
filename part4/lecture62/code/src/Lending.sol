// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lending {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    address public admin;
    address[] public assets;

    function depositMany(address[] calldata tokens, uint256[] calldata amounts) external {
        require(status == MarketStatus.Active, "not active");
        require(tokens.length == amounts.length, "length");
        // 金額の記録はユーザーごとの欄ができてから
    }
}
