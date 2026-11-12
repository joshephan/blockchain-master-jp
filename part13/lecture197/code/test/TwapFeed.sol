// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IPriceFeed} from "../src/MarketTypes.sol";

// 第197講: テスト用の価格の出どころ。価格を変えた時刻ごとに記録しておき、secondsAgo秒前までに積み上げた価格の合計(価格 × 秒)を返す
// 記録がその時点より短ければ巻き戻す。価格を書く関数に権限の確認なし(テスト用)
contract TwapFeed is IPriceFeed {
    uint256[] public times;
    uint256[] public prices;

    error ShortHistory(uint256 since, uint256 want);

    constructor(uint256 price) {
        times.push(block.timestamp);
        prices.push(price);
    }

    function setPrice(uint256 price) external {
        times.push(block.timestamp);
        prices.push(price);
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256 sum) {
        uint256 t = block.timestamp - secondsAgo;
        if (t < times[0]) revert ShortHistory(times[0], t);
        for (uint256 i = 0; i < times.length && times[i] < t; i++) {
            uint256 end = i + 1 < times.length && times[i + 1] < t ? times[i + 1] : t;
            sum += prices[i] * (end - times[i]);
        }
    }
}
