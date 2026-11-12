// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
