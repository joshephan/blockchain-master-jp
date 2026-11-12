// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/// @notice 講義用のトークン。移すたびにTransferログを出す
/// @dev feeBpsが0でなければ受け取る側にその分少なく入り、差はownerへ行く(移すときに引く手数料)
contract ToyToken67 {
    string public symbol;
    uint256 public immutable feeBps; // 万分率、100なら1%
    address public immutable owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory symbol_, uint256 feeBps_) {
        symbol = symbol_;
        feeBps = feeBps_;
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "not owner");
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        _move(from, to, amount);
        return true;
    }

    function _move(address from, address to, uint256 amount) internal {
        uint256 fee = amount * feeBps / 10000;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        emit Transfer(from, to, amount - fee);
        if (fee > 0) {
            balanceOf[owner] += fee;
            emit Transfer(from, owner, fee);
        }
    }
}

/// @notice Marketと同じ形のDepositedログを出す別のコントラクト。トークンは移さない
contract Echo67 {
    event Deposited(address indexed asset, address indexed user, uint256 amount);

    function echo(address asset, address user, uint256 amount) external {
        emit Deposited(asset, user, amount);
    }
}

/// @notice プロキシの裏に置く実装の二つの版
contract Impl67A {
    function version() external pure returns (uint256) {
        return 1;
    }
}

contract Impl67B {
    function version() external pure returns (uint256) {
        return 2;
    }
}
