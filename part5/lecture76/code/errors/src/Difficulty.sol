// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Difficulty {
    function both() external view returns (uint256 d, uint256 r) {
        d = block.difficulty;
        r = block.prevrandao;
    }
}
