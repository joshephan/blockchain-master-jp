// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CounterV1, CounterV2} from "../src/Init177.sol";

contract Init177Test is Test {
    address owner = makeAddr("owner");
    address stranger = makeAddr("stranger");

    function _deploy() internal returns (CounterV1 impl, CounterV1 c) {
        impl = new CounterV1();
        // プロキシを作るトランザクションの中でinitializeまで呼ぶ
        ERC1967Proxy p = new ERC1967Proxy(address(impl), abi.encodeCall(CounterV1.initialize, (owner)));
        c = CounterV1(address(p));
    }

    // 実装アドレスに直接initializeを呼んでも巻き戻す
    function test_implInitializeLocked() public {
        (CounterV1 impl,) = _deploy();
        vm.prank(stranger);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        impl.initialize(stranger);
        assertEq(impl.owner(), address(0));
    }

    // 同じトランザクションでオーナーが決まったプロキシへの二回目のinitializeは巻き戻す
    function test_proxyInitOnce() public {
        (, CounterV1 c) = _deploy();
        assertEq(c.owner(), owner);
        vm.prank(stranger);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        c.initialize(stranger);
        assertEq(c.owner(), owner);
    }

    function test_upgradeOnlyOwner() public {
        (, CounterV1 c) = _deploy();
        CounterV2 v2 = new CounterV2();
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(CounterV1.NotOwner.selector, stranger));
        c.upgradeToAndCall(address(v2), "");
        vm.prank(owner);
        c.upgradeToAndCall(address(v2), "");
        assertEq(CounterV2(address(c)).version(), 2);
        assertEq(c.owner(), owner); // オーナーの欄はプロキシのストレージなのでそのまま
    }
}
