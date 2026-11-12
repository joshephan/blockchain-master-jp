// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

library Mix {
    function half(uint256 x) internal pure returns (uint256) { return x / 2; }
    function third(uint256 x) public pure returns (uint256) { return x / 3; }
}

contract UseHalf {
    function f(uint256 x) external pure returns (uint256) { return Mix.half(x); }
}

contract UseThird {
    function f(uint256 x) external pure returns (uint256) { return Mix.third(x); }
}
