// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第194講の講義用の最小トークン。残高・承認・移転だけがある
abstract contract ToyErc20 {
    uint8 public immutable decimals;
    uint256 public totalSupply;
    mapping(address who => uint256) public balanceOf;
    mapping(address owner => mapping(address spender => uint256)) public allowance;

    error NoAllowance(address spender, uint256 have, uint256 need);

    constructor(uint8 decimals_) {
        decimals = decimals_;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 have = allowance[from][msg.sender];
        if (have < amount) revert NoAllowance(msg.sender, have, amount);
        allowance[from][msg.sender] = have - amount;
        _move(from, to, amount);
        return true;
    }

    // 受け取る側に入る量はトークンごとに違うことがある(手数料トークンは少なく入る)
    function _move(address from, address to, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}

// 第194講のテスト用トークン。誰でも発行できる
contract ToyToken is ToyErc20 {
    constructor(uint8 decimals_) ToyErc20(decimals_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// 第194講のテスト用の手数料トークン。移すたびに1%をバーン(受け取る側には99%だけが入る)
contract FeeToken is ToyErc20 {
    constructor() ToyErc20(18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _move(address from, address to, uint256 amount) internal override {
        uint256 fee = amount / 100;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        totalSupply -= fee;
    }
}
