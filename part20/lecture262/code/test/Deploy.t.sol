// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {MultiSigAdmin} from "./helpers/MultiSigAdmin.sol";

// 運用の要件O-03(デプロイスクリプトと確認リスト)。デプロイスクリプトのdeploy・checkをそのまま呼ぶ
contract DeployTest is Test {
    Deploy script;
    MultiSigAdmin council;
    address a = address(0xA);
    address b = address(0xB);
    address c = address(0xC);

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = a;
        owners[1] = b;
        owners[2] = c;
        council = new MultiSigAdmin(owners, 2);
        script = new Deploy();
    }

    // デプロイ二件のあと確認リストが全部通り、デプロイした側(スクリプト)に残るロールなし
    function test_O03_deployLeavesNoDeployerRole() public {
        (TimelockController timelock, Market market) = script.deploy(address(council));
        script.check(timelock, market, address(council), address(script));
        assertEq(market.admin(), address(timelock));
        assertEq(market.guardian(), address(council));
        assertEq(uint256(vm.load(address(market), bytes32(uint256(4)))), uint256(uint160(address(council))));
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(script)));
        assertEq(timelock.getMinDelay(), 2 days);
    }

    // デプロイ先アドレスはデプロイアカウントとナンスで決まる: 送る前に計算できる
    function test_O03_addressesFromNonce() public {
        uint64 n = vm.getNonce(address(script));
        (TimelockController timelock, Market market) = script.deploy(address(council));
        assertEq(address(timelock), vm.computeCreateAddress(address(script), n));
        assertEq(address(market), vm.computeCreateAddress(address(script), n + 1));
    }

    // マルチシグの席にコードがないアドレス(書き間違えたアドレス)は送る前に止まる
    function test_O03_rejectsCouncilWithoutCode() public {
        vm.expectRevert(abi.encodeWithSelector(Deploy.CheckFailed.selector, "council has no code"));
        script.checkCouncil(address(0xC0FFEE));
        script.checkCouncil(address(council));
    }

    // マルチシグのアドレスを間違えてデプロイすると確認リストが止まる。そのMarketは誰も設定できない(設定キーはimmutable)
    function test_O03_wrongCouncilFailsCheck() public {
        (TimelockController timelock, Market market) = script.deploy(address(0xC0FFEE));
        vm.expectRevert(abi.encodeWithSelector(Deploy.CheckFailed.selector, "market guardian"));
        script.check(timelock, market, address(council), address(script));
    }

    // デプロイ後の最初の設定: マルチシグがタイムロックに上げ、2日後に実行。2日前はできない
    function test_O03_firstListingWaitsTwoDays() public {
        (TimelockController timelock, Market market) = script.deploy(address(council));
        StdToken col = new StdToken("Collateral", "COL", 18);
        TwapFeed feed = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        bytes memory data = abi.encodeCall(IMarket.listAsset, (address(col), feed, 75, type(uint256).max));
        _council(
            address(timelock),
            abi.encodeCall(timelock.schedule, (address(market), 0, data, bytes32(0), bytes32(uint256(1)), 2 days))
        );
        bytes memory exec =
            abi.encodeCall(timelock.execute, (address(market), 0, data, bytes32(0), bytes32(uint256(1))));
        vm.prank(a);
        uint256 early = council.propose(address(timelock), exec);
        vm.prank(a);
        council.approve(early);
        vm.prank(b);
        council.approve(early);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.CallFailed.selector, early));
        council.execute(early);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        _council(address(timelock), exec);
        assertEq(market.assetCount(), 1);
    }

    function _council(address target, bytes memory data) internal {
        vm.prank(a);
        uint256 id = council.propose(target, data);
        vm.prank(a);
        council.approve(id);
        vm.prank(b);
        council.approve(id);
        vm.prank(a);
        council.execute(id);
    }
}
