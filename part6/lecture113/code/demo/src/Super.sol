// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第113講のデモ: superが呼ぶ次の順番
contract Base {
    function who() public pure virtual returns (string memory) {
        return "Base";
    }
}

contract A is Base {
    function who() public pure virtual override returns (string memory) {
        return string.concat("A ", super.who());
    }
}

contract B is Base {
    function who() public pure virtual override returns (string memory) {
        return string.concat("B ", super.who());
    }
}

contract C is A, B {
    function who() public pure override(A, B) returns (string memory) {
        return string.concat("C ", super.who());
    }
}

// isの順番だけを変えた版
contract D is B, A {
    function who() public pure override(A, B) returns (string memory) {
        return string.concat("D ", super.who());
    }
}

// Bだけをデプロイすると、BのsuperはBase
contract OnlyB is B {}

// 名前を直接指定すると列を飛ばして二回呼ぶ
contract E is A, B {
    function who() public pure override(A, B) returns (string memory) {
        return string.concat("E [", A.who(), "] [", B.who(), "]");
    }
}

// superを後ろに書くと前後が入れ替わる
contract A2 is Base {
    function who() public pure virtual override returns (string memory) {
        return string.concat(super.who(), " A2");
    }
}

contract F is A2, B {
    function who() public pure override(A2, B) returns (string memory) {
        return string.concat("F ", super.who());
    }
}

// B3がsuperを呼ばない
contract B3 is Base {
    function who() public pure virtual override returns (string memory) {
        return "B3";
    }
}

contract G is A, B3 {
    function who() public pure override(A, B3) returns (string memory) {
        return string.concat("G ", super.who());
    }
}

// 第110講のHeavyをsuperで呼ぶと、上書きされた本体がまた入ってくる
contract Heavy2 {
    function f() public pure virtual returns (uint256) {
        uint256 x = 1;
        for (uint256 i = 0; i < 10; i++) { x = x * 3 + i; }
        return uint256(keccak256(abi.encodePacked(x, "a long string to make the body bigger")));
    }
}
contract OverHeavySuper is Heavy2 {
    function f() public pure override returns (uint256) { return super.f() + 1; }
}
