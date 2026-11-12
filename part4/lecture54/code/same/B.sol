// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Same {
    address payable public to;

    function set(address payable v) external {
        to = v;
    }
}
