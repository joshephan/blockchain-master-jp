// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Sum10 {
    uint256[10] public v;

    function sum() external view returns (uint256 s) {
        for (uint256 i = 0; i < v.length; i++) {
            s += v[i];
        }
    }
}

contract Sum100 {
    uint256[100] public v;

    function sum() external view returns (uint256 s) {
        for (uint256 i = 0; i < v.length; i++) {
            s += v[i];
        }
    }
}

contract Sum1000 {
    uint256[1000] public v;

    function sum() external view returns (uint256 s) {
        for (uint256 i = 0; i < v.length; i++) {
            s += v[i];
        }
    }
}
