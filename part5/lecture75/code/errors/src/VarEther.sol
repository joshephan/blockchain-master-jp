// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract VarEther {
    function toWei(uint256 amount) external pure returns (uint256) {
        return amount ether;
    }
}
