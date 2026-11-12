// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PackNested {
    function f(uint256[][] memory xs) external pure returns (bytes memory) {
        return abi.encodePacked(xs);
    }
}
