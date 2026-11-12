// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Self {
    function who() public view returns (address) {
        return msg.sender;
    }

    function viaInternal() external view returns (address) {
        return who();
    }

    function viaThis() external view returns (address) {
        return this.who();
    }

    function me() external view returns (address) {
        return address(this);
    }
}
