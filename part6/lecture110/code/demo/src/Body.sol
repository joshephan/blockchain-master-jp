// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第110講のデモ: 上書きされた親の本体がデプロイ物に残るか
contract Light {
    function f() public pure virtual returns (uint256) { return 1; }
}
contract Heavy {
    function f() public pure virtual returns (uint256) {
        uint256 x = 1;
        for (uint256 i = 0; i < 10; i++) { x = x * 3 + i; }
        return uint256(keccak256(abi.encodePacked(x, "a long string to make the body bigger")));
    }
}
contract OverLight is Light {
    function f() public pure override returns (uint256) { return 2; }
}
contract OverHeavy is Heavy {
    function f() public pure override returns (uint256) { return 2; }
}
