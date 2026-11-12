// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// テスト用のアカウントのコード二つ。Marketは呼んだアドレス(msg.sender)だけを見る

// 持ち主一人が呼ぶコントラクトウォレット
contract OwnerWallet {
    address public immutable owner;

    constructor(address owner_) {
        owner = owner_;
    }

    function exec(address to, bytes calldata data) external returns (bytes memory) {
        require(msg.sender == owner, "not owner");
        (bool ok, bytes memory ret) = to.call(data);
        require(ok, "call failed");
        return ret;
    }
}

// EIP-7702でEOAに委任するコード。EOA自身が呼ぶときだけ複数の呼び出しを順に実行
contract BatchAccount {
    struct Call {
        address to;
        bytes data;
    }

    function execute(Call[] calldata calls) external {
        require(msg.sender == address(this), "only self");
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok,) = calls[i].to.call(calls[i].data);
            require(ok, "call failed");
        }
    }
}
