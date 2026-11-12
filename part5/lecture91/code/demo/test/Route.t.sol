// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Target, InsufficientDeposit} from "../src/Target.sol";

contract RouteTest is Test {
    Target t;

    function setUp() public {
        t = new Target();
    }

    function route(function() external fn) internal returns (string memory) {
        try fn() {
            return "returns";
        } catch Error(string memory reason) {
            return string.concat("catch Error  reason=", reason);
        } catch Panic(uint256 code) {
            return string.concat("catch Panic  code=", vm.toString(abi.encodePacked(uint8(code))));
        } catch (bytes memory data) {
            return string.concat("catch (bytes) data=", vm.toString(data));
        }
    }

    function test_route() public {
        console.log("require     ", route(t.failRequire));
        console.log("assert      ", route(t.failAssert));
        console.log("overflow    ", route(t.failOverflow));
        console.log("custom error", route(t.failCustom));
        console.log("revert()    ", route(t.failEmpty));
        console.log("bad Error   ", route(t.failBadError));
        console.log("count       ", t.count());
    }
}

contract OnlyErrorTest is Test {
    Target t;

    function setUp() public {
        t = new Target();
    }

    // catch節がErrorの一つだけ
    function onlyError(function() external fn) internal returns (string memory) {
        try fn() {
            return "returns";
        } catch Error(string memory reason) {
            return reason;
        }
    }

    function test_onlyError_require() public {
        console.log(onlyError(t.failRequire));
    }

    function test_onlyError_panic() public {
        console.log(onlyError(t.failOverflow));
    }
}
