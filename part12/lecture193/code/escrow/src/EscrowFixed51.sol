// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IToken51} from "./Escrow51.sol";

// 直した版: refundに確認済みかのチェックを一行足す。残りはEscrow51と同じ
contract EscrowFixed51 {
    error NotBuyer();
    error NotSeller();
    error AlreadyFunded();
    error NotConfirmed();
    error AlreadySettled();
    error TooEarly();
    error AlreadyConfirmed();

    IToken51 public immutable token;
    address public immutable buyer;
    address public immutable seller;
    uint256 public immutable deadline;

    uint256 public amount;
    bool public confirmed;
    bool public settled;

    constructor(IToken51 token_, address buyer_, address seller_, uint256 deadline_) {
        token = token_;
        buyer = buyer_;
        seller = seller_;
        deadline = deadline_;
    }

    function fund(uint256 a) external {
        if (msg.sender != buyer) revert NotBuyer();
        if (amount != 0) revert AlreadyFunded();
        amount = a;
        token.transferFrom(msg.sender, address(this), a);
    }

    function confirm() external {
        if (msg.sender != buyer) revert NotBuyer();
        confirmed = true;
    }

    function release() external {
        if (msg.sender != seller) revert NotSeller();
        if (!confirmed) revert NotConfirmed();
        if (settled) revert AlreadySettled();
        settled = true;
        token.transfer(seller, amount);
    }

    function refund() external {
        if (msg.sender != buyer) revert NotBuyer();
        if (block.timestamp <= deadline) revert TooEarly();
        if (confirmed) revert AlreadyConfirmed(); // 直した行: 確認した後は払い戻しを受けられない
        if (settled) revert AlreadySettled();
        settled = true;
        token.transfer(buyer, amount);
    }
}
