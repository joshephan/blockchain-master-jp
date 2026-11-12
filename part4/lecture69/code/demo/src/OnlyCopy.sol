// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract OnlyCopy {
    function restCopy(bytes calldata data) external pure returns (uint256, bytes1) {
        bytes memory rest = data[4:];
        return (rest.length, rest[0]);
    }
}
