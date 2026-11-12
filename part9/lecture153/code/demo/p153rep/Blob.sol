// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Blob {
    function fee() external view returns (uint256) {
        return block.blobbasefee;
    }
}
