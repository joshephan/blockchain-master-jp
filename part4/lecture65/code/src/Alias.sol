// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Alias {
    uint256[3] public x;
    uint256[3] public y;

    function memoryAlias() external pure returns (uint256, uint256) {
        uint256[3] memory a = [uint256(1), 2, 3];
        uint256[3] memory b = a;
        b[0] = 7;
        return (a[0], b[0]);
    }

    function stateCopy() external {
        y[0] = 1;
        x = y;
        y[0] = 9;
    }
}
