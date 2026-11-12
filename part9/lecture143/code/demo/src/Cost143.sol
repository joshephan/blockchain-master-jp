// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第143講: ストレージの欄の読み書き、transient、ログ、ハッシュ、外部呼び出しを一回ずつ。optimizerをオフにした版でトレースを見る
contract Other143 {
    function ping() external pure returns (uint256) {
        return 1;
    }
}

contract Cost143 {
    uint256 a;
    uint256 b = 1;
    uint256 transient t;
    Other143 public other;

    event E0();
    event E1(uint256 indexed x);
    event E2(uint256 indexed x, uint256 indexed y);
    event Data(uint256 x, uint256 y);

    constructor(Other143 o) {
        other = o;
    }

    function readOnce() external view returns (uint256) {
        return a;
    }

    function readThree() external view returns (uint256) {
        uint256 x = b;
        uint256 y = b;
        uint256 z = b;
        return x + y + z;
    }

    function writeA(uint256 v) external {
        a = v;
    }

    function writeSame() external {
        b = b;
    }

    function tWriteRead(uint256 v) external returns (uint256) {
        t = v;
        return t;
    }

    function logs() external {
        emit E0();
        emit E1(1);
        emit E2(1, 2);
        emit Data(1, 2);
    }

    function hash(bytes calldata d) external pure returns (bytes32) {
        return keccak256(d);
    }

    function callTwice() external view returns (uint256) {
        return other.ping() + other.ping();
    }
}
