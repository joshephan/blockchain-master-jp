// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract A {
    function f() public pure virtual returns (uint256) { return 1; }
}
contract B is A {
    function f() public pure override returns (uint256) { return 2; }
}
contract C is B {
    function f() public pure override returns (uint256) { return 3; }
}
