// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract InternalValue {
    function readValue() internal view returns (uint256) {
        return msg.value;
    }

    function noPay() external view returns (uint256) {
        return readValue();
    }
}
