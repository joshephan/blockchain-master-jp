// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第211講: 他のチェーンから渡ってきた形のテスト用トークン。発行する側(minter)と止める側(guardian)がデプロイ時に決まる
// 止めるとtransfer・transferFromの両方がTokenPausedでリバート。Marketのコードとは関係ないトークン側の権限
contract BridgedToken {
    error TokenPaused();
    error NotMinter(address caller);
    error NotGuardian(address caller);

    address public immutable minter;
    address public immutable guardian;
    bool public paused;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address minter_, address guardian_) {
        minter = minter_;
        guardian = guardian_;
    }

    function mint(address to, uint256 value) external {
        if (msg.sender != minter) revert NotMinter(msg.sender);
        totalSupply += value;
        balanceOf[to] += value;
    }

    function setPaused(bool p) external {
        if (msg.sender != guardian) revert NotGuardian(msg.sender);
        paused = p;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        if (paused) revert TokenPaused();
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (paused) revert TokenPaused();
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }
}
