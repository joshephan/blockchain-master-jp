// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IToken51 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// 講義用のエスクロー: 購入者が預け、受け取ったと確認すると販売者が引き出す。締め切りまで確認がなければ購入者が払い戻しを受ける
contract Escrow51 {
    error NotBuyer();
    error NotSeller();
    error AlreadyFunded();
    error NotConfirmed();
    error AlreadySettled();
    error TooEarly();

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

    // 購入者が品物を受け取ったと確認
    function confirm() external {
        if (msg.sender != buyer) revert NotBuyer();
        confirmed = true;
    }

    // 確認の後、販売者が引き出す
    function release() external {
        if (msg.sender != seller) revert NotSeller();
        if (!confirmed) revert NotConfirmed();
        if (settled) revert AlreadySettled();
        settled = true;
        token.transfer(seller, amount);
    }

    // 締め切りが過ぎると購入者が払い戻しを受ける
    function refund() external {
        if (msg.sender != buyer) revert NotBuyer();
        if (block.timestamp <= deadline) revert TooEarly();
        if (settled) revert AlreadySettled();
        settled = true;
        token.transfer(buyer, amount);
    }
}
