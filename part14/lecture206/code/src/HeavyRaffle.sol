// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {MockCoordinator, IRandomConsumer} from "./MockCoordinator.sol";

// 第206講の比較用: 受け取る関数の中で参加者リストを全部回って記録を書く形。参加者が多いとガスリミットに引っかかってリバートする
contract HeavyRaffle is IRandomConsumer {
    MockCoordinator public immutable coordinator;
    address[] public players;
    mapping(address who => uint256) public lastWord;
    bool public drawing;
    uint256 public requestId;
    address public winner;

    constructor(MockCoordinator c) {
        coordinator = c;
    }

    function enter() external {
        players.push(msg.sender);
    }

    function draw() external {
        require(!drawing);
        drawing = true;
        requestId = coordinator.requestRandomWords(100_000);
    }

    function rawFulfillRandomWords(uint256 id, uint256 w) external {
        require(msg.sender == address(coordinator) && id == requestId);
        for (uint256 i = 0; i < players.length; i++) {
            lastWord[players[i]] = w;
        }
        winner = players[w % players.length];
        drawing = false;
    }
}
