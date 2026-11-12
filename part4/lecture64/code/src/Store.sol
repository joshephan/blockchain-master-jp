// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Store {
    uint256[] public s;

    function build(uint256 n) external pure returns (uint256) {
        uint256[] memory m = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            m[i] = i + 1;
        }
        return m.length;
    }

    function put(uint256 n) external {
        uint256[] memory m = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            m[i] = i + 1;
        }
        s = m;
    }
}
