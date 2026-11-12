// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
pragma abicoder v1;

import "./Packer.sol";

contract Shop is Packer {
    function packOne(uint256 amount) external view returns (bytes memory) {
        return pack(Order(msg.sender, amount));
    }
}
