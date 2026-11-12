// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第170講の外部呼び出しの結果処理とpull paymentの縮小版。トイ、ローカルのforge専用。

// 脆弱性1: 一人ずつ押し付けて送る途中で一人が止めると全員が止まる(push payment)
contract PushPayout {
    address[] public recipients;

    function addRecipient(address r) external {
        recipients.push(r);
    }

    // 全員に同じだけ分けて送る。一人が巻き戻すと全体が巻き戻る
    function payAll() external payable {
        uint256 each = msg.value / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            (bool ok,) = recipients[i].call{value: each}("");
            require(ok, "one recipient blocked all"); // 一人が止めるとここで全体が巻き戻る
        }
    }
}

// 修正: 帳簿に記録しておき、各自が取りに来るようにする(pull payment)
contract PullPayout {
    mapping(address => uint256) public owed;
    address[] public recipients;

    function addRecipient(address r) external {
        recipients.push(r);
    }

    function fund() external payable {
        uint256 each = msg.value / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            owed[recipients[i]] += each; // 送らずに記録するだけ
        }
    }

    function withdraw() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }
}

// 受け取りを拒否する受取人
contract Rejecter {
    receive() external payable {
        revert("no thanks");
    }
}

// 脆弱性2: 低水準のcallの結果を見ずに進む(静かな失敗)
contract Ignorer {
    bool public done;

    function pay(address to, uint256 amount) external {
        to.call{value: amount}(""); // 戻り値を受け取らない → 失敗しても次の行が実行される
        done = true; // 実際に送ったかとは関係なくtrue
    }

    receive() external payable {}
}
