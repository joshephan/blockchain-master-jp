// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P2 {
    function ext() external pure returns (uint256) { return 1; }
}

contract ChildExt is P2 {
    function g() external pure returns (uint256) {
        return ext();
    }
}
