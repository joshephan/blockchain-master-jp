// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IPriceFeed} from "../../src/MarketTypes.sol";

// 第207講: 主の出どころがリバートしたら予備の出どころを使う。両方生きているのに30分平均がMAX_SPREAD_BPSより開いたらリバート
// 両方リバートしたらリバート。出どころ二つと開きの上限はデプロイ時に決め、変える関数はない
contract FallbackFeed is IPriceFeed {
    uint32 public constant WINDOW = 30 minutes; // MarketのTWAP_WINDOWと同じ値
    uint256 public constant MAX_SPREAD_BPS = 200; // 2%、講義用の設計値
    IPriceFeed public immutable primary;
    IPriceFeed public immutable secondary;

    error Diverged(uint256 primaryAverage, uint256 secondaryAverage);
    error NoSource();

    constructor(IPriceFeed primary_, IPriceFeed secondary_) {
        primary = primary_;
        secondary = secondary_;
    }

    function averageOf(IPriceFeed f) external view returns (uint256) {
        return (f.cumulativePrice(0) - f.cumulativePrice(WINDOW)) / WINDOW;
    }

    function _tryAverage(IPriceFeed f) internal view returns (bool ok, uint256 avg) {
        try this.averageOf(f) returns (uint256 v) {
            return (true, v);
        } catch {
            return (false, 0);
        }
    }

    function pick() public view returns (IPriceFeed) {
        (bool okP, uint256 p) = _tryAverage(primary);
        (bool okS, uint256 s) = _tryAverage(secondary);
        if (okP && okS) {
            uint256 hi = p > s ? p : s;
            uint256 lo = p > s ? s : p;
            if ((hi - lo) * 10_000 > lo * MAX_SPREAD_BPS) revert Diverged(p, s);
            return primary;
        }
        if (okP) return primary;
        if (okS) return secondary;
        revert NoSource();
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256) {
        return pick().cumulativePrice(secondsAgo);
    }
}
