// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// blobトランザクションの中でコントラクトが見られる値
contract BlobProbe {
    bytes32 public h0;
    bytes32 public h1;
    bytes32 public h2;
    uint256 public blobFee;
    uint256 public calls;

    function probe() external {
        h0 = blobhash(0);
        h1 = blobhash(1);
        h2 = blobhash(2);
        blobFee = block.blobbasefee;
        calls += 1;
    }
}
