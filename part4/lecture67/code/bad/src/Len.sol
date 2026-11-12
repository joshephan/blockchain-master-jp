// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Len {
    function grow() public pure returns (uint256) {
        uint256[] memory r = new uint256[](3);
        r.length = 5;
        return r.length;
    }
}
