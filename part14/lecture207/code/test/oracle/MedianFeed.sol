// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IPriceFeed} from "../../src/MarketTypes.sol";

// 第207講: 価格の出どころ三つの30分平均のうち中央値を出した出どころの累積合計を返す。出どころ三つはデプロイ時に決め、変える関数はない
// 一つでもリバートしたら一緒にリバート(三つ全部そろって中央値)
contract MedianFeed is IPriceFeed {
    uint32 public constant WINDOW = 30 minutes; // MarketのTWAP_WINDOWと同じ値
    IPriceFeed public immutable a;
    IPriceFeed public immutable b;
    IPriceFeed public immutable c;

    constructor(IPriceFeed a_, IPriceFeed b_, IPriceFeed c_) {
        a = a_;
        b = b_;
        c = c_;
    }

    function averageOf(IPriceFeed f) public view returns (uint256) {
        return (f.cumulativePrice(0) - f.cumulativePrice(WINDOW)) / WINDOW;
    }

    function pick() public view returns (IPriceFeed) {
        uint256 x = averageOf(a);
        uint256 y = averageOf(b);
        uint256 z = averageOf(c);
        if ((x <= y && y <= z) || (z <= y && y <= x)) return b;
        if ((y <= x && x <= z) || (z <= x && x <= y)) return a;
        return c;
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256) {
        return pick().cumulativePrice(secondsAgo);
    }
}
