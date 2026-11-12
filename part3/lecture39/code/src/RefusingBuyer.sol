// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Purchase} from "./Purchase.sol";

// イーサを受け取ると無条件で巻き戻す購入者
contract RefusingBuyer {
    Purchase public purchase;

    constructor(Purchase purchase_) payable {
        purchase = purchase_;
    }

    function buy() external {
        purchase.confirmPurchase{value: 2 * purchase.value()}();
    }

    function received() external {
        purchase.confirmReceived();
    }

    receive() external payable {
        revert();
    }
}
