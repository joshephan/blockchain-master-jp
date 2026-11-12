// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Members {
    function look(address a)
        external
        view
        returns (uint256 bal, uint256 codeLen, bytes32 hash)
    {
        bal = a.balance;
        codeLen = a.code.length;
        hash = a.codehash;
    }
}
