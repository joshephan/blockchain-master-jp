// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメントの本文が言うtransferの形(ドキュメントの例のコードはcall)。送る行だけが違う
contract SendTransfer {
    address payable public richest;
    uint256 public mostSent;

    error NotEnoughEther();

    constructor() payable {
        richest = payable(msg.sender);
        mostSent = msg.value;
    }

    function becomeRichest() public payable {
        if (msg.value <= mostSent) revert NotEnoughEther();
        richest.transfer(msg.value);
        richest = payable(msg.sender);
        mostSent = msg.value;
    }
}
