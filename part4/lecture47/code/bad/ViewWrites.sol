// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ViewWrites {
    uint256 public visits;

    function preview() external view returns (uint256) {
        visits += 1;
        return visits;
    }
}
