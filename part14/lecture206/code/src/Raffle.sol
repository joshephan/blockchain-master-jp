// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {MockCoordinator, IRandomConsumer} from "./MockCoordinator.sol";

// 第206講: チェーンの外の乱数で当選者を選ぶ抽選。要求したあとは参加・再要求・取り消しなし
// 受け取る関数は乱数を書くだけで終わる。当選者選びはsettleで別に
contract Raffle is IRandomConsumer {
    enum State {
        Open,
        Drawing,
        Drawn
    }

    MockCoordinator public immutable coordinator;
    address[] public players;
    State public state;
    uint256 public requestId;
    uint256 public word;
    address public winner;

    error NotOpen(State state);
    error NoPlayers();
    error OnlyCoordinator(address have, address want);
    error WrongRequest(uint256 have, uint256 want);
    error NotDrawn(State state);

    constructor(MockCoordinator c) {
        coordinator = c;
    }

    function enter() external {
        if (state != State.Open) revert NotOpen(state);
        players.push(msg.sender);
    }

    function draw() external {
        if (state != State.Open) revert NotOpen(state);
        if (players.length == 0) revert NoPlayers();
        state = State.Drawing;
        requestId = coordinator.requestRandomWords(100_000);
    }

    function rawFulfillRandomWords(uint256 id, uint256 w) external {
        if (msg.sender != address(coordinator)) revert OnlyCoordinator(msg.sender, address(coordinator));
        if (id != requestId) revert WrongRequest(id, requestId);
        word = w;
        state = State.Drawn;
    }

    function settle() external returns (address) {
        if (state != State.Drawn) revert NotDrawn(state);
        if (winner == address(0)) winner = players[word % players.length];
        return winner;
    }

    function playerCount() external view returns (uint256) {
        return players.length;
    }
}
