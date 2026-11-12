// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
library Lib141 {
    struct S { uint256 x; }
    enum K { A, B }
    function bump(S storage s, uint256 a) public { s.x += a; }
    function pick(K k, uint256[] storage xs) public view returns (uint256) { return uint256(k) + xs.length; }
    function plain(uint256 a) public pure returns (uint256) { return a; }
}
