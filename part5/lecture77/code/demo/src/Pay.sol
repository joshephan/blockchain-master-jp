// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Pay {
    function pay() external payable returns (uint256) {
        return msg.value;
    }

    function noPay() external pure returns (uint256) {
        return 1;
    }
}
