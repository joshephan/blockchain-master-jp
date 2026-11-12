// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第110講のデモ: 親一つ、子一つ
contract Counter {
    uint256 public count;          // スロット0
    uint256 private secret = 42;   // スロット1、子は名前で使えない
    address public lastCaller;     // スロット2

    event Bumped(address caller, uint256 count);

    function bump() public {
        count += 1;
        lastCaller = msg.sender;
        emit Bumped(msg.sender, count);
    }

    function step() public pure virtual returns (uint256) {
        return 1;
    }

    // 親の中でstep()を呼ぶ
    function bumpBy() public {
        count += step();
        lastCaller = msg.sender;
    }

    function _hidden() private pure returns (uint256) { return 7; }
    function _shared() internal pure returns (uint256) { return 8; }
}

contract Child is Counter {
    uint256 public extra;          // スロット3

    function step() public pure override returns (uint256) {
        return 10;
    }

    function useShared() external pure returns (uint256) {
        return _shared();
    }
}

// オーバーロード: 引数の型が違うstep
contract Overload is Counter {
    function step(uint8 by) public pure returns (uint256) {
        return by;
    }
}
