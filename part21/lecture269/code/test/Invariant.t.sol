// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {FeeSwitchToken} from "./helpers/OddTokens.sol";
import {Handler} from "./helpers/Handler.sol";

// 設計文書5節の不変条件I-1~I-5をランダムな順番で。順番はHandlerが選ぶ(ハンドラーの外の関数は呼ばない)
// I-1・I-2は順番のあとごとに状態で、I-3~I-5は呼び出しごとにハンドラーが数えておいた値で確認
contract InvariantTest is Test {
    Market market;
    Handler handler;
    address[3] assets;
    address[4] actors = [address(0xA11CE), address(0xB0B), address(0xCA201), address(0xDA7E)];

    function setUp() public {
        StdToken usd = new StdToken("Dollar", "USD", 6);
        StdToken col = new StdToken("Collateral", "COL", 18);
        FeeSwitchToken fee = new FeeSwitchToken();
        assets = [address(usd), address(col), address(fee)];
        TwapFeed[3] memory feeds = [new TwapFeed(1e18), new TwapFeed(1e18), new TwapFeed(1e18)];
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        market = new Market(address(this), address(this), 0.05e18);
        market.listAsset(address(usd), feeds[0], 80, type(uint256).max);
        market.listAsset(address(col), feeds[1], 75, type(uint256).max);
        market.listAsset(address(fee), feeds[2], 50, type(uint256).max);
        for (uint256 i = 0; i < 4; i++) {
            usd.mint(actors[i], 10_000e6);
            col.mint(actors[i], 10_000e18);
            fee.mint(actors[i], 10_000e18);
            for (uint256 j = 0; j < 3; j++) {
                vm.prank(actors[i]);
                StdToken(assets[j]).approve(address(market), type(uint256).max);
            }
        }
        // 最初の預け金: bob USD 5,000・dave FEE 5,000(借りていくお金があるマーケットで始める)
        vm.prank(actors[1]);
        market.deposit(address(usd), 5000e6);
        vm.prank(actors[3]);
        market.deposit(address(fee), 5000e18);
        handler = new Handler(market, address(this), assets, feeds, actors);
        targetContract(address(handler));
        bytes4[] memory sel = new bytes4[](15);
        sel[0] = Handler.deposit.selector;
        sel[1] = Handler.withdraw.selector;
        sel[2] = Handler.withdrawAll.selector;
        sel[3] = Handler.setCollateral.selector;
        sel[4] = Handler.borrow.selector;
        sel[5] = Handler.repay.selector;
        sel[6] = Handler.liquidate.selector;
        sel[7] = Handler.writeOff.selector;
        sel[8] = Handler.warp.selector;
        sel[9] = Handler.setPrice.selector;
        sel[10] = Handler.setFee.selector;
        sel[11] = Handler.pause.selector;
        sel[12] = Handler.unpause.selector;
        sel[13] = Handler.openPosition.selector;
        sel[14] = Handler.openPosition.selector; // 借金を負うひとまとまりを二倍の頻度で
        targetSelector(FuzzSelector({addr: address(handler), selectors: sel}));
    }

    // I-1: 金庫のトークン + 貸し出した借金 ≥ 預けた人が引き出す量の合計(資産ごと)
    function invariant_I1_vaultCoversPromises() public view {
        for (uint256 j = 0; j < 3; j++) {
            uint256 promised;
            for (uint256 i = 0; i < 4; i++) {
                promised += market.depositOf(assets[j], actors[i]);
            }
            uint256 vault = StdToken(assets[j]).balanceOf(address(market)) + market.totalBorrows(assets[j]);
            assertGe(vault, promised);
        }
    }

    // I-2: 持ち分の合計の欄 = アカウントの持ち分の合計(資産ごと、預け入れ側・借り入れ側)
    function invariant_I2_sharesAddUp() public view {
        for (uint256 j = 0; j < 3; j++) {
            (uint256 sd, uint256 sb,,,) = market.reserves(assets[j]);
            uint256 d;
            uint256 b;
            for (uint256 i = 0; i < 4; i++) {
                (uint256 pd, uint256 pb,) = market.positions(assets[j], actors[i]);
                d += pd;
                b += pb;
            }
            assertEq(sd, d);
            assertEq(sb, b);
        }
    }

    // I-3: 借り入れ側の指数は下がらない。預け入れ側の指数は借金の消去でだけ下がる
    function invariant_I3_indexes() public view {
        assertEq(handler.indexDropped(), 0);
    }

    // I-4: 借り入れ・担保としてオンにした資産の引き出し・担保のオフが成功した直後、そのアカウントの借金の値 ≤ 借入上限
    // 担保でない資産の引き出しは上限を見ない(S-01)。最初の文(引き出し全部)はその引き出しで崩れた
    function invariant_I4_healthAfterSuccess() public view {
        assertEq(handler.healthBroken(), 0);
    }

    // I-5: 引き出し・返済・清算・借金の消去・担保のオフは停止・キーのエラーで失敗しない
    function invariant_I5_exitsNotBlocked() public view {
        assertEq(handler.exitBlocked(), 0);
    }

    // リストにない失敗(Panic、空のリバート)がない
    function invariant_noUnexpectedFailure() public view {
        assertEq(handler.unexpected(), 0, vm.toString(abi.encodePacked(handler.lastUnexpected())));
    }
}
