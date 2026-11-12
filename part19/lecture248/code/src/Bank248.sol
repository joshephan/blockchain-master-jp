// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// 残高を帳簿の数字として置くEVMの形。moveが移す行
contract Bank248 {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function move(address to, uint256 amount) external virtual {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}

// 引く行が抜けた版: 受け取る側だけが増える
contract BankNoDebit248 is Bank248 {
    function move(address to, uint256 amount) external override {
        balanceOf[to] += amount;
    }
}

// 足す行が抜けた版: 送る側だけが減る
contract BankNoCredit248 is Bank248 {
    function move(address, uint256 amount) external override {
        balanceOf[msg.sender] -= amount;
    }
}
