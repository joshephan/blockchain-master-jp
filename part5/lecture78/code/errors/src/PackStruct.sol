// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PackStruct {
    struct Pair {
        uint256 x;
        bool y;
    }

    function f() external pure returns (bytes memory) {
        Pair memory p = Pair(5, true);
        return abi.encodePacked(p);
    }
}
