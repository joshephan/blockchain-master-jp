// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract EncErr {
    error Short(uint256 have, uint256 want);

    function f() external pure returns (bytes memory) {
        return abi.encodeError(Short, (1, 2));
    }
}
