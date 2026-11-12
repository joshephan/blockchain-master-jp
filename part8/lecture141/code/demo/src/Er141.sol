// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメントの例そのまま
contract TestToken {
    error InsufficientBalance(uint256 available, uint256 required);
    function transfer(address /*to*/, uint amount) public pure {
        revert InsufficientBalance(0, amount);
    }
}

// 名前だけ同じエラーを別に宣言したコントラクト。TestTokenとは何の関係もない
contract Faker {
    error InsufficientBalance(uint256 available, uint256 required);
    function transfer(address, uint amount) public pure {
        revert InsufficientBalance(0, amount);
    }
    function raw(bytes calldata data) external pure {
        // 受け取ったバイト列をそのまま巻き戻りデータに
        bytes memory d = data;
        assembly { revert(add(d, 32), mload(d)) }
    }
    function str() external pure { revert("no"); }
    function panic(uint256 x) external pure returns (uint256) { return 10 / x; }
}
