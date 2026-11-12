// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../../src/Market.sol";
import {IMarket} from "../../src/IMarket.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";
import {FeeSwitchToken} from "./OddTokens.sol";

// 不変条件テストのハンドラー。ランダムな順番をユーザー・キーが実際にできる呼び出しに絞る
// 資産三つ(USD 6桁・COL 18桁・FEE 18桁の手数料をオンにできるトークン)、アカウント四つ、キー一つ(テストコントラクトが設定キー・停止キー)
// 金額はアカウントの残高・預けた量・借金の内側に、価格は0.2~2.0、時間は一度に1秒~10日
// Marketが要件どおりに拒否した呼び出しはハンドラーもリバート(成功・拒否の数はforgeの表のCalls・Reverts、選ばなかった入力はDiscards)
// リストにない失敗(Panicなど)と、停止・キーのエラーでふさがれた引き出しの道はリバートせずに数えておく
contract Handler is Test {
    Market public market;
    address public key;
    address[3] public assets;
    TwapFeed[3] public feeds;
    address[4] public actors;

    // ゴースト: 帳簿の外で別に数える値
    uint256 public unexpected;
    bytes4 public lastUnexpected;
    uint256 public healthBroken; // I-4: 借り入れ・引き出し・担保のオフが成功した直後に借金の値 > 上限
    uint256 public exitBlocked; // I-5: 引き出し・返済・清算・借金の消去・担保のオフが停止・キーのエラーで失敗
    uint256 public indexDropped; // I-3: 借り入れ側の指数が下がった、預け入れ側の指数が借金の消去の外で下がった
    uint256 public minPrice = 0.2e18;

    constructor(Market m, address key_, address[3] memory a, TwapFeed[3] memory f, address[4] memory u) {
        market = m;
        key = key_;
        assets = a;
        feeds = f;
        actors = u;
    }

    function setMinPrice(uint256 p) external {
        minPrice = p;
    }

    // ---------- ユーザー ----------

    function deposit(uint256 who, uint256 a, uint256 amount) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        uint256 bal = StdToken(asset).balanceOf(u);
        vm.assume(bal != 0);
        amount = _bound(amount, 1, bal);
        _try("deposit", u, abi.encodeCall(IMarket.deposit, (asset, amount)), false);
    }

    function withdraw(uint256 who, uint256 a, uint256 amount) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        amount = _bound(amount, 1, market.depositOf(asset, u) + 1);
        if (_try("withdraw", u, abi.encodeCall(IMarket.withdraw, (asset, amount)), true)) _checkHealth(u);
    }

    function withdrawAll(uint256 who, uint256 a) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        vm.assume(market.depositOf(asset, u) != 0);
        if (_try("withdrawAll", u, abi.encodeCall(IMarket.withdrawAll, (asset)), true)) _checkHealth(u);
    }

    function setCollateral(uint256 who, uint256 a, bool on) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        if (_try("setCollateral", u, abi.encodeCall(IMarket.setCollateral, (asset, on)), !on) && !on) _checkHealth(u);
    }

    function borrow(uint256 who, uint256 a, uint256 amount) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        amount = _bound(amount, 1, market.totalDeposits(asset) + 1);
        if (_try("borrow", u, abi.encodeCall(IMarket.borrow, (asset, amount)), false)) _checkHealth(u);
    }

    function repay(uint256 who, uint256 a, uint256 amount) external {
        address u = actors[who % 4];
        address asset = assets[a % 3];
        uint256 debt = market.debtOf(asset, u);
        vm.assume(debt != 0);
        amount = _bound(amount, 1, debt + 1);
        if (amount > StdToken(asset).balanceOf(u)) amount = StdToken(asset).balanceOf(u);
        vm.assume(amount != 0);
        _try("repay", u, abi.encodeCall(IMarket.repay, (asset, amount)), true);
    }

    function liquidate(uint256 by, uint256 who, uint256 d, uint256 c, uint256 amount) external {
        address liq = actors[by % 4];
        address borrower = actors[who % 4];
        address debtAsset = assets[d % 3];
        address colAsset = assets[c % 3];
        uint256 debt = market.debtOf(debtAsset, borrower);
        vm.assume(debt != 0);
        amount = _bound(amount, 1, debt);
        _try("liquidate", liq, abi.encodeCall(IMarket.liquidate, (borrower, debtAsset, colAsset, amount)), true);
    }

    function writeOff(uint256 who, uint256 a) external {
        address borrower = actors[who % 4];
        address asset = assets[a % 3];
        _try("writeOff", address(this), abi.encodeCall(IMarket.writeOffBadDebt, (borrower, asset)), true);
    }

    // ---------- 外側(時間、価格、トークン、キー) ----------

    function warp(uint256 secs) external {
        vm.warp(vm.getBlockTimestamp() + _bound(secs, 1, 10 days));
    }

    function setPrice(uint256 a, uint256 p) external {
        uint256 i = a % 3;
        vm.assume(i != 0); // USDの出どころは1.0のまま
        feeds[i].setPrice(_bound(p, minPrice, 2e18));
    }

    function setFee(bool on) external {
        FeeSwitchToken(assets[2]).setFee(on ? 100 : 0);
    }

    function pause(uint256 a, uint8 bits) external {
        vm.prank(key);
        market.pause(assets[a % 3], bits % 4);
    }

    function unpause(uint256 a, uint8 bits) external {
        vm.prank(key);
        market.unpause(assets[a % 3], bits % 4);
    }

    // ---------- 内部 ----------

    function _try(bytes32 name, address caller, bytes memory data, bool exitPath) internal returns (bool success) {
        uint256[3] memory b;
        uint256[3] memory s;
        for (uint256 i = 0; i < 3; i++) {
            (,, s[i], b[i],) = market.reserves(assets[i]);
        }
        bytes memory err;
        vm.prank(caller);
        (success, err) = address(market).call(data);
        if (!success) {
            bytes4 sel = bytes4(err);
            if (!_listed(sel)) {
                unexpected++;
                lastUnexpected = sel;
                return false;
            }
            if (exitPath && (sel == IMarket.ActionPaused.selector || sel == IMarket.NotAdmin.selector)) {
                exitBlocked++;
                return false;
            }
            assembly {
                revert(add(err, 32), mload(err))
            }
        }
        for (uint256 i = 0; i < 3; i++) {
            (,, uint256 s2, uint256 b2,) = market.reserves(assets[i]);
            if (b2 < b[i]) indexDropped++;
            if (s2 < s[i] && name != "writeOff") indexDropped++;
        }
    }

    function _checkHealth(address u) internal {
        (uint256 limit, uint256 debt) = market.accountHealth(u);
        if (debt > limit) healthBroken++;
    }

    // 正常な失敗とみなすリバート(要件が決めた確認)。Panic(0x4e487b71)と空のリバートはリストにない
    function _listed(bytes4 sel) internal pure returns (bool) {
        return sel == IMarket.ZeroAmount.selector || sel == IMarket.ZeroShares.selector
            || sel == IMarket.ActionPaused.selector || sel == IMarket.InsufficientDeposit.selector
            || sel == IMarket.InsufficientLiquidity.selector || sel == IMarket.InsufficientCollateral.selector
            || sel == IMarket.NoDebt.selector || sel == IMarket.NotLiquidatable.selector
            || sel == IMarket.NotCollateral.selector || sel == IMarket.AboveCloseFactor.selector
            || sel == IMarket.HasCollateral.selector || sel == IMarket.LossExceedsDeposits.selector
            || sel == IMarket.AmountMismatch.selector || sel == IMarket.SupplyCapExceeded.selector;
    }
}
