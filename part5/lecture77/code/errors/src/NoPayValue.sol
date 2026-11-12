// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract NoPayValue {
    function noPay() external returns (uint256) {
        return msg.value;
    }
}
