// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {Nft, Multi} from "./helpers/OddTokens.sol";
import {OwnerWallet, BatchAccount} from "./helpers/Accounts.sol";
import {IMarket} from "../src/IMarket.sol";

// 標準の対照表(design/architecture.md 9節)の行ごとに確認
contract StandardsTest is Base {
    TwapFeed f;

    function setUp() public {
        _deploy(0);
        f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
    }

    // ERC-721・ERC-1155のアドレスはdecimalsがないので上場でリバート(受け付けるトークンはERC-20一つ)
    function test_nonErc20Rejected() public {
        address n = address(new Nft());
        address m = address(new Multi());
        vm.expectRevert();
        market.listAsset(n, f, 50, type(uint256).max);
        vm.expectRevert();
        market.listAsset(m, f, 50, type(uint256).max);
        assertEq(market.assetCount(), 2);
    }

    // ERC-165の応答関数なし。呼ぶとリバート(fallbackなし)
    function test_noErc165() public {
        (bool ok,) = address(market).call(abi.encodeWithSignature("supportsInterface(bytes4)", bytes4(0x01ffc9a7)));
        assertFalse(ok);
    }

    // コントラクトウォレットが預けて借りる。帳簿はウォレットのアドレス宛て
    function test_contractWallet() public {
        OwnerWallet w = new OwnerWallet(alice);
        col.mint(address(w), 1000e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        w.exec(address(col), abi.encodeWithSignature("approve(address,uint256)", address(market), 1000e18));
        w.exec(address(market), abi.encodeCall(IMarket.deposit, (address(col), 1000e18)));
        w.exec(address(market), abi.encodeCall(IMarket.setCollateral, (address(col), true)));
        w.exec(address(market), abi.encodeCall(IMarket.borrow, (address(usd), 100e6)));
        vm.stopPrank();
        assertEq(market.depositOf(address(col), address(w)), 1000e18);
        assertEq(market.debtOf(address(usd), address(w)), 100e6);
        assertEq(usd.balanceOf(address(w)), 100e6);
        assertEq(market.depositOf(address(col), alice), 0);
    }

    // EIP-7702で委任したEOAが承認・預け入れ・担保のオン・借り入れを取引一つで。帳簿はEOAのアドレス宛て
    function test_delegatedEoaBatch() public {
        uint256 key = 0xE0A;
        address eoa = vm.addr(key);
        BatchAccount impl = new BatchAccount();
        col.mint(eoa, 1000e18);
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        BatchAccount.Call[] memory calls = new BatchAccount.Call[](4);
        calls[0] = BatchAccount.Call(
            address(col), abi.encodeWithSignature("approve(address,uint256)", address(market), 1000e18)
        );
        calls[1] = BatchAccount.Call(address(market), abi.encodeCall(IMarket.deposit, (address(col), 1000e18)));
        calls[2] = BatchAccount.Call(address(market), abi.encodeCall(IMarket.setCollateral, (address(col), true)));
        calls[3] = BatchAccount.Call(address(market), abi.encodeCall(IMarket.borrow, (address(usd), 200e6)));
        vm.signAndAttachDelegation(address(impl), key);
        vm.prank(eoa);
        BatchAccount(eoa).execute(calls);
        assertEq(eoa.code, abi.encodePacked(hex"ef0100", address(impl)));
        assertEq(market.depositOf(address(col), eoa), 1000e18);
        assertEq(market.debtOf(address(usd), eoa), 200e6);
        assertEq(usd.balanceOf(eoa), 200e6);
    }

    // 小数の桁数は上場のときに一度読んでおく
    function test_decimalsReadOnce() public view {
        (, uint8 dc,,,,) = market.assetConfig(address(col));
        (, uint8 du,,,,) = market.assetConfig(address(usd));
        assertEq(dc, 18);
        assertEq(du, 6);
    }
}
