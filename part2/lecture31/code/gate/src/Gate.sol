// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Gate {
    function open(uint256 x) public pure returns (bool) {
        if (keccak256(abi.encode(x)) ==
            0x25cbcc7eb4cc357312d8bada948e6254c329b5007dd242ed95169991bf96730d) {
            return false;
        }
        return true;
    }
}
