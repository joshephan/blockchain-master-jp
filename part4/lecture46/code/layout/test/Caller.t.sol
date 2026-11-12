// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Caller} from "../src/Caller.sol";
import {IToken} from "../src/interfaces/IToken.sol";

contract FakeToken {
    function transfer(address, uint) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint) {
        return 1000000;
    }
}

contract CallerTest is Test {
    function test_FakeTokenSaysTrue() public {
        Caller caller = new Caller();
        FakeToken fake = new FakeToken();
        assertTrue(caller.send(IToken(address(fake)), address(0xB0B), 10));
    }
}
