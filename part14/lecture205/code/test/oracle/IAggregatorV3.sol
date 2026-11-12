// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第204講: プッシュ型の価格フィードが出す関数の形(公式ドキュメントのAPIリファレンスの関数名・戻り値の順番)。フィード側のコードではない
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
