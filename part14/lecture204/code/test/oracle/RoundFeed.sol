// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IPriceFeed} from "../../src/MarketTypes.sol";
import {IAggregatorV3} from "./IAggregatorV3.sol";

// 第204講: プッシュ型のフィードをMarketの価格の出どころ(IPriceFeed)につなぐアダプター。変える関数はない
// 最後の答えをウィンドウ全体で同じ値とみなして累積合計を返す(Marketの平均 = 最後の答え)
// 答えが0以下、終わっていないラウンドはリバート。桁数はフィードのdecimalsを読んで倍率10の18乗に合わせる
// 第205講: 最後の答えがmaxAge秒より古ければリバート
contract RoundFeed is IPriceFeed {
    IAggregatorV3 public immutable aggregator;
    uint256 public immutable maxAge;

    error BadAnswer(int256 answer);
    error IncompleteRound(uint80 roundId);
    error StaleRound(uint256 updatedAt, uint256 maxAge);

    constructor(IAggregatorV3 aggregator_, uint256 maxAge_) {
        aggregator = aggregator_;
        maxAge = maxAge_;
    }

    function latestPrice() public view returns (uint256) {
        (uint80 roundId, int256 answer,, uint256 updatedAt,) = aggregator.latestRoundData();
        if (answer <= 0) revert BadAnswer(answer);
        if (updatedAt == 0) revert IncompleteRound(roundId);
        if (block.timestamp - updatedAt > maxAge) revert StaleRound(updatedAt, maxAge);
        return uint256(answer) * 1e18 / 10 ** aggregator.decimals();
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256) {
        return latestPrice() * (block.timestamp - secondsAgo);
    }
}
