// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Label {
    string public label;

    function setLabel(string calldata s) external {
        label = s;
    }
}
