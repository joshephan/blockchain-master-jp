// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

struct Book {
    uint256 count;
    mapping(address => uint256) owed;
}

contract MapMemory {
    Book book;

    function _add(Book memory b) internal pure {
        b.count += 1;
    }
}
