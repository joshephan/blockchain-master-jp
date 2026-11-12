// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {GovToken, Gov58} from "./GovParts58.sol";
import {TimelockController} from "../vendor/oz/governance/TimelockController.sol";

// Marketのソースはそのまま、デプロイ引数adminにタイムロックのアドレスを入れた版
contract GovMarket58Test is Test {
    GovToken gtoken;
    TimelockController tl;
    Gov58 gov;
    Market market;
    MockToken token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        gtoken = new GovToken(1000);
        gtoken.transfer(alice, 100);
        vm.prank(alice);
        gtoken.delegate(alice);
        address[] memory none = new address[](0);
        tl = new TimelockController(2 days, none, none, address(this));
        gov = new Gov58(gtoken, tl, 1, 50, 0, 4);
        tl.grantRole(tl.PROPOSER_ROLE(), address(gov));
        tl.grantRole(tl.CANCELLER_ROLE(), address(gov));
        tl.grantRole(tl.EXECUTOR_ROLE(), address(0));
        tl.renounceRole(tl.DEFAULT_ADMIN_ROLE(), address(this));
        token = new MockToken();
        market = new Market(address(tl), Rate.wrap(5e16), Ratio.wrap(80));
        token.transfer(bob, 1000);
        vm.roll(10);
    }

    // 提案 → 投票 → キュー。実行の直前で止まる
    function _queue(bytes memory data, string memory desc) internal returns (address[] memory t, uint256[] memory v, bytes[] memory c) {
        t = new address[](1);
        v = new uint256[](1);
        c = new bytes[](1);
        t[0] = address(market);
        c[0] = data;
        vm.prank(alice);
        uint256 id = gov.propose(t, v, c, desc);
        vm.roll(vm.getBlockNumber() + 2);
        vm.prank(alice);
        gov.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + 50);
        gov.queue(t, v, c, keccak256(bytes(desc)));
    }

    function _list() internal {
        (address[] memory t, uint256[] memory v, bytes[] memory c) =
            _queue(abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(75))), "list token 75");
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("list token 75")));
    }

    function test_adminIsTimelock() public view {
        assertEq(market.admin(), address(tl));
    }

    function test_addAssetThroughGovernance() public {
        uint256 b0 = vm.getBlockNumber();
        uint256 t0 = vm.getBlockTimestamp();
        (address[] memory t, uint256[] memory v, bytes[] memory c) =
            _queue(abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(75))), "list token 75");
        vm.expectRevert(); // 待機2日の前
        gov.execute(t, v, c, keccak256(bytes("list token 75")));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("list token 75")));
        assertEq(market.assetCount(), 1);
        emit log_named_uint("blocks waited", vm.getBlockNumber() - b0);
        emit log_named_uint("seconds waited", vm.getBlockTimestamp() - t0);
    }

    function test_governorIsNotAdmin() public {
        vm.prank(address(gov));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, address(gov)));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, alice));
        market.setStatus(IMarket.MarketStatus.Frozen);
    }

    function test_pauseWaitsForDelay() public {
        _list();
        vm.prank(bob);
        market.deposit(address(token), 100);
        (address[] memory t, uint256[] memory v, bytes[] memory c) =
            _queue(abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.DepositPaused)), "pause deposits");
        // 止めようという提案が可決して待っているあいだも預け入れが入ってくる
        vm.prank(bob);
        market.deposit(address(token), 50);
        // 出金もそのまま
        vm.prank(bob);
        market.withdraw(address(token), 30);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        gov.execute(t, v, c, keccak256(bytes("pause deposits")));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.DepositPaused));
        market.deposit(address(token), 1);
        vm.prank(bob);
        market.withdraw(address(token), 120);
        assertEq(token.balanceOf(bob), 1000);
    }
}
