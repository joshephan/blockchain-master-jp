// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SetLength {
    uint256[] public list;

    function clear() external {
        list.length = 0;
    }
}
