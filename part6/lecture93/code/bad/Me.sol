// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Me {
    function myCode() external pure returns (bytes memory) {
        return type(Me).creationCode;
    }
}
