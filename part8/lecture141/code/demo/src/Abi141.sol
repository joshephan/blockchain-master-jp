// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Price is uint128;
enum Side { Buy, Sell }
struct Pair { uint256 a; uint256 b; }
struct Bag { uint256 id; uint256[] xs; }
interface IThing { function ping() external; }

contract Abi141 {
    function canon(uint x, Side s, Price p, IThing t, address payable q) external {}
    function tup(Pair calldata p, Bag calldata b) external {}
    function fn(function() external f) external {}
    function arrs(uint256[2] calldata a, string[2] calldata b) external {}

    function pairs(Pair calldata, uint256) external pure returns (bytes memory) { return msg.data; }
    function bags(Bag calldata, uint256) external pure returns (bytes memory) { return msg.data; }
    function rawFn(function() external) external pure returns (bytes memory) { return msg.data; }
    function ret() external pure returns (Pair memory p, Bag memory b, uint256 z) {
        p = Pair(1, 2);
        b.id = 3;
        b.xs = new uint256[](2);
        b.xs[0] = 4;
        b.xs[1] = 5;
        z = 6;
    }
    function one() external pure returns (uint32) { return 7; }
    function three() external pure returns (uint32, bool, string memory) { return (7, true, "hi"); }
}
