// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Vault {
    mapping(address => uint256) public balances;

    function deposit() external payable returns (uint256) {
        balances[msg.sender] += msg.value;
        return balances[msg.sender];
    }

    // イーサを先に送り、欄を後で直す (デモ用)
    function withdrawSendFirst() external {
        uint256 amount = balances[msg.sender];
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
        balances[msg.sender] = 0;
    }

    // 欄を先に直してからイーサを送る
    function withdrawStateFirst() external {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
    }
}

// 受け取る側: イーサを受け取った瞬間に金庫を読むだけ
contract Peeker {
    Vault public v;
    uint256 public seenEntry;
    uint256 public seenVaultEth;

    constructor(Vault _v) payable {
        v = _v;
    }

    function put() external {
        v.deposit{value: 1 ether}();
    }

    function takeSendFirst() external {
        v.withdrawSendFirst();
    }

    function takeStateFirst() external {
        v.withdrawStateFirst();
    }

    receive() external payable {
        seenEntry = v.balances(address(this));
        seenVaultEth = address(v).balance;
    }
}
