// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Dedup139 {
    error Low(uint256 have, uint256 want);
    error Paused(uint8 s);

    uint8 public s;

    function a(uint256 x) external pure {
        if (x < 10) revert Low(x, 10);
    }

    function b() external view {
        if (s != 0) revert Paused(s);
    }

    function setS(uint8 v) external {
        s = v;
    }
}
