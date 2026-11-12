// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bad1 {
    uint256 public count = 3;

    function readCall() external view returns (uint256) {
        return count();
    }
}
