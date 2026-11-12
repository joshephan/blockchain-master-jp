// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IAggregatorV3} from "./IAggregatorV3.sol";

// 第204講: テスト用のフィード。答えを書くたびにラウンド番号を一つ上げ、その時刻を書く
// 書く関数に権限の確認なし(テスト用)。setRoundは終わっていないラウンド(updatedAt 0)のまね
contract RoundAggregator is IAggregatorV3 {
    uint8 public immutable decimals;
    uint80 public roundId;
    int256 public answer;
    uint256 public updatedAt;

    constructor(uint8 decimals_, int256 answer_) {
        decimals = decimals_;
        transmit(answer_);
    }

    function transmit(int256 answer_) public {
        roundId++;
        answer = answer_;
        updatedAt = block.timestamp;
    }

    function setRound(int256 answer_, uint256 updatedAt_) external {
        roundId++;
        answer = answer_;
        updatedAt = updatedAt_;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, answer, updatedAt, updatedAt, roundId);
    }
}
