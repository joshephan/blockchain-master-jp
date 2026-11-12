// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit2 {
    function f() public pure returns (uint256) {
        uint256[] memory b = [uint256(1), 2, 3];
        return b[0];
    }
}
