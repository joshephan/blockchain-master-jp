// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {StdToken} from "./StdToken.sol";

// 標準と違う動きをするテスト用のトークン

// 移すときに手数料を引けるトークン。最初は0、setFeeでオン(受け取る側が少なく受け取る、引いた分は消える)
contract FeeSwitchToken is StdToken {
    uint256 public feeBps;

    constructor() StdToken("Fee", "FEE", 18) {}

    function setFee(uint256 bps) external {
        feeBps = bps;
    }

    function _move(address from, address to, uint256 amount) internal override {
        uint256 fee = amount * feeBps / 10_000;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        totalSupply -= fee;
        emit Transfer(from, to, amount - fee);
    }
}

// transfer・transferFromが何も返さないトークン(戻り値のない形)
contract NoReturnToken {
    uint8 public constant decimals = 6;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
    }

    function transfer(address to, uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) external {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}

// 残高が足りなければリバートせずfalseを返すトークン
contract FalseToken is StdToken {
    constructor() StdToken("False", "FALSE", 18) {}

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        if (balanceOf[from] < amount || allowance[from][msg.sender] < amount) return false;
        allowance[from][msg.sender] -= amount;
        _move(from, to, amount);
        return true;
    }
}
