// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Label {
    uint256 public count = 42;

    function label() external view returns (string memory) {
        return string.concat("count: ", Strings.toString(count));
    }
}
