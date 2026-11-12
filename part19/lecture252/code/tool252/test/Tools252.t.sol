// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Store251} from "../src/Store251.sol";

interface IStore {
    function setValue(uint256) external;
    function getValue() external view returns (uint256);
}

// 同じテストをSolidityの版と手で移したバイトの版で回す
contract Tools252Test is Test {
    address hand = address(0x4242);

    function setUp() public {
        vm.etch(hand, hex"60003560e01c8063552410771461001c5780632096525514610023575b6004356000555b60005460005260206000f360006000fd");
    }

    function test_sameAbiBothPass() public {
        Store251 s = new Store251();
        s.setValue(5);
        IStore(hand).setValue(5);
        assertEq(s.getValue(), IStore(hand).getValue());
    }

    function test_unknownSelectorSolidity() public {
        Store251 s = new Store251();
        (bool ok,) = address(s).call(abi.encodeWithSelector(0xdeadbeef, uint256(9)));
        assertFalse(ok);
    }

    function test_unknownSelectorHand() public {
        (bool ok,) = hand.call(abi.encodeWithSelector(0xdeadbeef, uint256(9)));
        assertTrue(ok);
        assertEq(IStore(hand).getValue(), 9);
    }
}
