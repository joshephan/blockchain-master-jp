// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract WrongType {
    uint256 public count;

    function reset() public {
        count = "zero";
    }
}
