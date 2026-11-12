// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第135講: スロットマップのバイト位置をドキュメントの規則(Layout of State Variables in Storage)どおりに計算し、vm.loadで照合
contract LayoutTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    // スロット1(assets)には長さだけ。要素はkeccak256(1)から一つの欄に一つ(アドレスは20バイトなので一つの欄に二つは入らない)
    function test_assetsData() public view {
        assertEq(uint256(vm.load(address(market), bytes32(uint256(1)))), 1);
        bytes32 first = keccak256(abi.encode(uint256(1)));
        assertEq(address(uint160(uint256(vm.load(address(market), first)))), address(token));
    }

    // assetConfig[asset]はkeccak256(asset . 2)の一つの欄。collateralRatio(uint8) オフセット0、listed(bool) オフセット1
    function test_assetConfigPacked() public view {
        bytes32 slot = keccak256(abi.encode(address(token), uint256(2)));
        assertEq(uint256(vm.load(address(market), slot)), 0x014b);
    }

    // positions[asset][user]はkeccak256(user . keccak256(asset . 3))から三つの欄
    // +0 deposited、+1 borrowed、+2 lastUpdate(uint64 オフセット0)とuseAsCollateral(bool オフセット8)
    function test_positionWords() public {
        bytes32 inner = keccak256(abi.encode(address(token), uint256(3)));
        uint256 base = uint256(keccak256(abi.encode(address(this), inner)));
        assertEq(uint256(vm.load(address(market), bytes32(base))), 100);
        assertEq(uint256(vm.load(address(market), bytes32(base + 1))), 0);
        uint256 w2 = uint256(vm.load(address(market), bytes32(base + 2)));
        assertEq(w2, block.timestamp);
        // オフセット8のバイトに1を入れると、ゲッターとcollateralCountが担保として使用中と読む
        vm.store(address(market), bytes32(base + 2), bytes32(w2 | (uint256(1) << 64)));
        (,,, bool useAsCollateral) = market.positions(address(token), address(this));
        assertTrue(useAsCollateral);
        assertEq(market.collateralCount(address(this)), 1);
        // totalDeposits[asset]はkeccak256(asset . 4)
        assertEq(uint256(vm.load(address(market), keccak256(abi.encode(address(token), uint256(4))))), 100);
    }
}
