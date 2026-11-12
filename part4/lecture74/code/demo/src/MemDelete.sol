// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemDelete {
    function f() external pure returns (uint256 aLen, uint256 bLen, uint256 b0) {
        uint256[] memory a = new uint256[](2);
        a[0] = 7;
        a[1] = 8;
        uint256[] memory b = a;
        delete a;
        aLen = a.length;
        bLen = b.length;
        b0 = b[0];
    }
}
