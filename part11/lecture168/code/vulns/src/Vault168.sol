// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第168講の再入の基本形の縮小版: Solidityドキュメントsecurity-considerations.rstのFundのバグをトイに移したもの。
// 実在のサービスではない。ローカルのforgeテスト専用。

// 修正(CEI): チェック → 帳簿を0に(Effects) → 送る(Interactions)
contract GoodVault {
    mapping(address => uint256) public shares;

    function deposit() external payable {
        shares[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = shares[msg.sender];
        shares[msg.sender] = 0; // 送る前に0に
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }
}

// 直した金庫に対しても同じ受け取る側を使う(GoodVault専用)
contract ReentererGood {
    address public vault;
    uint256 public hits;

    constructor(address v) {
        vault = v;
    }

    function go() external payable {
        GoodVault(vault).deposit{value: msg.value}();
        GoodVault(vault).withdraw();
    }

    receive() external payable {
        // 自分の分が残っているときだけ再び入る。CEIの金庫は送る前に0にするので、ここで止まる
        if (GoodVault(vault).shares(address(this)) > 0) {
            hits++;
            GoodVault(vault).withdraw();
        }
    }
}
