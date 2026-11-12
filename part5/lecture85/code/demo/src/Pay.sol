// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Token {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract Pay {
    Token public token;
    uint256 public seen;

    constructor(Token t) {
        token = t;
    }

    function note(uint256 bal, bool ok) internal pure returns (uint256) {
        require(ok);
        return bal;
    }

    // 引数の二つの位置: 残高の読み取りとトークンの送金
    function payOne(address to) external {
        seen = note(token.balanceOf(address(this)), token.transfer(to, 1));
    }
}
