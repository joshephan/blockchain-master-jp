// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PureSender {
    function who() external pure returns (address) {
        return msg.sender;
    }
}
