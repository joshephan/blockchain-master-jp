// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Order126 {
    uint256[] public calls;
    function a() internal returns (uint256) { calls.push(1); return 5; }
    function b() internal returns (uint256) { calls.push(2); return 6; }
    function c() internal returns (uint256) { calls.push(3); return 7; }
    function plain(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) { return (x + y) % z; }
    function runAddmod() external returns (uint256 r, uint256[] memory order) {
        delete calls;
        r = addmod(a(), b(), c());
        order = calls;
    }
    function runExpr() external returns (uint256 r, uint256[] memory order) {
        delete calls;
        r = a() + b() * c();
        order = calls;
    }
    function runPlain() external returns (uint256 r, uint256[] memory order) {
        delete calls;
        r = plain(a(), b(), c());
        order = calls;
    }
}
