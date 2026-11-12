// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {TwapOracle} from "./Oracle173.sol";

// 第173講の直した版。担保価値をスポット価格の代わりに時間加重平均で評価
// 最小の形: ウィンドウの開始はデプロイ時点一つに固定(ウィンドウをずらす部分は省略)
contract TwapLender {
    TwapOracle public immutable oracle;
    uint256 public immutable minWindow;
    uint256 public immutable startCumulative;
    uint256 public immutable startTimestamp;
    mapping(address => uint256) public collateralA;

    constructor(TwapOracle o, uint256 window) {
        oracle = o;
        minWindow = window;
        startCumulative = o.priceCumulative();
        startTimestamp = block.timestamp;
    }

    function putCollateral(address who, uint256 amountA) external {
        collateralA[who] += amountA;
    }

    // ウィンドウがminWindowより短ければ値を出さない
    function maxBorrowB(address who) external view returns (uint256) {
        if (block.timestamp - startTimestamp < minWindow) revert WindowTooShort();
        return collateralA[who] * oracle.consult(startCumulative, startTimestamp) / 1e18;
    }

    error WindowTooShort();
}
