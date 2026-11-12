// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract O {
    uint256 private secret = 42;
}

contract OtherPriv {
    function g(O o) external view returns (uint256) {
        return o.secret();
    }
}
