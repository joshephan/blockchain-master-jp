// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TryInternal {
    function risky() internal pure returns (uint256) {
        return 1;
    }

    function run() external pure returns (uint256) {
        try risky() returns (uint256 v) {
            return v;
        } catch {
            return 0;
        }
    }
}
