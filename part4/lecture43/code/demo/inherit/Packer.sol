// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
pragma abicoder v2;

abstract contract Packer {
    struct Order {
        address buyer;
        uint256 amount;
    }

    function pack(Order memory order) internal pure returns (bytes memory) {
        return abi.encode(order);
    }
}
