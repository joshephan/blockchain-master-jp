// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ThisInternal {
    function _who() internal view returns (address) {
        return msg.sender;
    }

    function viaThis() external view returns (address) {
        return this._who();
    }
}
