// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract OnlySlice {
    function restSlice(bytes calldata data) external pure returns (uint256, bytes1) {
        bytes calldata rest = data[4:];
        return (rest.length, rest[0]);
    }
}
