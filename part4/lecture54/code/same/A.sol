// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Same {
    address public to;

    function set(address v) external {
        to = v;
    }
}
