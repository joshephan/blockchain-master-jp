// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StrSlice {
    function head(string calldata s) external pure returns (string memory) {
        return s[0:3];
    }
}
