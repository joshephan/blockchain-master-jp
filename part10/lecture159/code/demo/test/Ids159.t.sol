// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

// erc-165の40~43行目の例(0.8.30の文法でintをそのまま)
interface Solidity101 {
    function hello() external pure;
    function world(int256) external pure;
}

// 名前と引数は同じで、戻り値の型・イベント・エラー・viewだけが違う二つ
interface ShapeA {
    event Moved(uint256 amount);

    function pay(address to, uint256 amount) external returns (bool);
    function owed(address who) external view returns (uint256);
}

interface ShapeB {
    error Nope();

    function pay(address to, uint256 amount) external;
    function owed(address who) external returns (int8);
}

// 名前を一つだけ変える(owed → debt)
interface ShapeC {
    function pay(address to, uint256 amount) external returns (bool);
    function debt(address who) external view returns (uint256);
}

contract Ids159Test is Test {
    function test_solidity101() public pure {
        console.logBytes4(Solidity101.hello.selector);
        console.logBytes4(Solidity101.world.selector);
        console.logBytes4(type(Solidity101).interfaceId);
        assertEq(type(Solidity101).interfaceId, Solidity101.hello.selector ^ Solidity101.world.selector);
    }

    function test_shapes() public pure {
        console.log("A");
        console.logBytes4(type(ShapeA).interfaceId);
        console.log("B");
        console.logBytes4(type(ShapeB).interfaceId);
        console.log("C");
        console.logBytes4(type(ShapeC).interfaceId);
        assertEq(type(ShapeA).interfaceId, type(ShapeB).interfaceId);
        assertTrue(type(ShapeA).interfaceId != type(ShapeC).interfaceId);
    }
}
