// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {InterestMath} from "../src/MarketMath.sol";
import {MockToken} from "../src/MockToken.sol";

// 第116講: ライブラリに切り出した計算がMarketの外部関数と同じ答えを出すか、PositionLibがMarketのストレージのPositionを直すか
contract LibraryTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    // 第116講: internalのライブラリ関数はこのテストコントラクトの中にも入ってくるので、直接呼べる
    function test_interestMathMatchesMarket() public view {
        uint256 direct = InterestMath.interestFor(1000e18, Rate.wrap(5e16), 365 days);
        assertEq(direct, 50e18);
        assertEq(market.interestFor(1000e18, Rate.wrap(5e16), 365 days), direct);
        assertEq(market.SECONDS_PER_YEAR(), 365 days);
    }

    // 第116講: PositionLib.creditが直した欄はMarketのアドレスのpositions(スロット3)の中
    function test_positionLibWritesMarketStorage() public {
        vm.warp(1000);
        market.deposit(address(token), 100);
        (uint256 deposited, , uint64 lastUpdate, ) = _position();
        assertEq(deposited, 100);
        assertEq(lastUpdate, 1000);
        bytes32 slot = keccak256(abi.encode(address(this), keccak256(abi.encode(address(token), uint256(3)))));
        assertEq(uint256(vm.load(address(market), slot)), 100);
    }

    function _position() internal view returns (uint256 deposited, uint256 borrowed, uint64 lastUpdate, bool useAsCollateral) {
        Amount d;
        Amount b;
        (d, b, lastUpdate, useAsCollateral) = market.positions(address(token), address(this));
        return (Amount.unwrap(d), Amount.unwrap(b), lastUpdate, useAsCollateral);
    }
}
