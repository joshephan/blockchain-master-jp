// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Observer249} from "../src/Observer249.sol";
import {Direct249} from "../src/Direct249.sol";
import {Actor249, Router249} from "../src/Actor249.sol";

contract Actor249Test is Test {
    Observer249 o;
    Router249 r;
    Actor249 act;

    function setUp() public {
        o = new Observer249();
        r = new Router249();
        act = new Actor249(address(r));
    }

    function test_directCallSeesHalf() public {
        Direct249 d = new Direct249();
        d.update(address(o));
        assertEq(o.seenA(), 1);
        assertEq(o.seenB(), 0);
        assertEq(d.b(), 1);
    }

    function test_actorMessageSeesFinal() public {
        r.run(act, address(o), false, false);
        assertEq(o.seenA(), 1);
        assertEq(o.seenB(), 1);
    }

    function test_directFailureContinues() public {
        Direct249 d = new Direct249();
        d.updateFailing(address(o));
        assertEq(d.lastOk(), false);
        assertEq(d.a(), 2);
        assertEq(d.b(), 2);
    }

    function test_actorFailureRevertsAll() public {
        vm.expectRevert(abi.encodeWithSelector(Router249.MessageFailed.selector, 0));
        r.run(act, address(o), true, false);
        assertEq(act.a(), 0);
        assertEq(act.b(), 0);
    }

    function test_actorReplyOnError() public {
        r.run(act, address(o), true, true);
        assertEq(act.a(), 1);
        assertEq(act.b(), 1);
        assertEq(act.replies(), 1);
        assertEq(act.lastReplyOk(), false);
    }

    function test_onlyRouterRuns() public {
        vm.expectRevert(Actor249.OnlyRouter.selector);
        act.update(address(o), false, false);
    }
}
