// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IPriceFeed} from "../../src/MarketTypes.sol";

// テスト用の価格の出どころ。価格を変えた時刻ごとに書いておき、secondsAgo秒前までに積み上がった価格の合計を返す
// 記録がその時点より短ければShortHistory、stop()のあとはStopped。setPriceに権限の確認なし(テスト用)
contract TwapFeed is IPriceFeed {
    uint256[] public times;
    uint256[] public prices;
    bool public stopped;

    error ShortHistory(uint256 since, uint256 want);
    error Stopped();

    constructor(uint256 price) {
        times.push(block.timestamp);
        prices.push(price);
    }

    function setPrice(uint256 price) external {
        times.push(block.timestamp);
        prices.push(price);
    }

    function stop() external {
        stopped = true;
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256 sum) {
        if (stopped) revert Stopped();
        uint256 t = block.timestamp - secondsAgo;
        if (t < times[0]) revert ShortHistory(times[0], t);
        for (uint256 i = 0; i < times.length && times[i] < t; i++) {
            uint256 end = i + 1 < times.length && times[i + 1] < t ? times[i + 1] : t;
            sum += prices[i] * (end - times[i]);
        }
    }
}
