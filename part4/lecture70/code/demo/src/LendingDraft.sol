// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256; // 金額、資産トークンのdecimalsのまま
type Rate is uint256;   // 利率、倍率10の18乗
type Ratio is uint8;    // 担保比率、倍率100

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

// ユーザー一人分
struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

contract LendingDraft {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    Ratio public collateralRatio;
    address public admin;
    Rate public interestRate;
    IERC20[] public assets;
    // ユーザーごとにPositionが一つ: まだ書けない
}
