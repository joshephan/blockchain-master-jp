// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 演算ごとにオーバーフローチェックが付くかを見る関数群
contract Ops {
    uint8 public count = 254;

    event Bumped(uint8 before);

    // チェックあり
    function add8(uint8 a, uint8 b) external pure returns (uint8) { return a + b; }
    function sub8(uint8 a, uint8 b) external pure returns (uint8) { return a - b; }
    function mul8(uint8 a, uint8 b) external pure returns (uint8) { return a * b; }
    function pow8(uint8 a, uint8 b) external pure returns (uint8) { return a ** b; }
    function div(uint256 a, uint256 b) external pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) external pure returns (uint256) { return a % b; }
    function divI8(int8 a, int8 b) external pure returns (int8) { return a / b; }
    function negI8(int8 a) external pure returns (int8) { return -a; }

    function bump() external {
        emit Bumped(count);
        count++;
    }

    function addTo(uint8 x) external {
        count += x;
    }

    // チェックなし
    function cast8(uint256 a) external pure returns (uint8) { return uint8(a); }
    function twoSteps(int16 a) external pure returns (uint8) { return uint8(int8(a)); }
    function shl8(uint8 a, uint8 n) external pure returns (uint8) { return a << n; }
    function not8(uint8 a) external pure returns (uint8) { return ~a; }
    function or8(uint8 a, uint8 b) external pure returns (uint8) { return a | b; }
}
