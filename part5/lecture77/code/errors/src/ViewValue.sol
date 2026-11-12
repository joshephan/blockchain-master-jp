// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ViewValue {
    function seen() external view returns (uint256) {
        return msg.value;
    }
}
