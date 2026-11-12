// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第241講: テスト用のトークン。上場時は手数料0、トークンの持ち主があとから手数料をオンにできる(移すときに引く分、万分率)
// 受け取る側には金額から手数料を引いた値が届き、引いた分はトークンの持ち主へ行く
contract FeeSwitchToken {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event FeeChanged(uint256 fromBps, uint256 toBps);

    error NotOwner(address caller);

    address public immutable owner;
    uint256 public feeBps;
    mapping(address => uint256) public balanceOf;

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = 1000;
    }

    function setFee(uint256 bps) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        emit FeeChanged(feeBps, bps);
        feeBps = bps;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _move(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function _move(address from, address to, uint256 amount) internal {
        uint256 fee = amount * feeBps / 10000;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        balanceOf[owner] += fee;
        emit Transfer(from, to, amount - fee);
        if (fee > 0) emit Transfer(from, owner, fee);
    }
}
