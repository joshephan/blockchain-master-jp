// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

library ArrLib {
    function first(uint[] storage xs) public view returns (uint) {
        return xs[0];
    }
}
