// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Target, Opt} from "../src/Options.sol";

contract OptionsTest is Test {
    Target t;
    Opt o;

    function setUp() public {
        t = new Target();
        o = new Opt{value: 1 ether}(t);
    }

    function test_optionsCalldata() public {
        vm.expectCall(address(t), 7, hex"ebf6e91d0000000000000000000000000000000000000000000000000000000000000003");
        o.withOptions();
    }

    function test_plain() public {
        o.plain();
    }

    function test_withOptions() public {
        o.withOptions();
    }

    function test_withGas() public {
        o.withGas();
    }

    function test_named() public {
        o.named();
    }

    function test_bumpLimited() public {
        o.bumpLimited();
    }

    function test_bumpFull() public {
        o.bumpFull();
    }
}
