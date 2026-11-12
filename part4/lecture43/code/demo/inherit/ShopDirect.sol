// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
pragma abicoder v1;

import "./Packer.sol";

contract ShopDirect is Packer {
    function packOne(uint256 amount) external view returns (bytes memory) {
        return abi.encode(Order(msg.sender, amount));
    }
}
