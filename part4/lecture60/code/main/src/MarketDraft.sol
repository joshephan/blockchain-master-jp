// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;     // 金額、資産トークンのdecimalsのまま
type Rate is uint256;       // 利率、倍率10の18乗
type Ratio is uint8;        // 担保比率、倍率100 (150 = 150%)

contract MarketDraft {
    enum MarketStatus { Active, DepositPaused, Frozen }

    MarketStatus public status;
    Ratio public collateralRatio;
    Rate public interestRate;
    Amount public totalDeposits;

    function depositAllowed() external view returns (bool) {
        return status == MarketStatus.Active;
    }
}
