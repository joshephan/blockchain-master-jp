// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount, Position} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第120講: アセンブリの.slot・.offsetでスロットマップを確認するテスト用コントラクト。デプロイ物のMarketにはアセンブリなし
// Marketを継承するので状態変数の名前が見える。状態変数は名前だけでは使えない(Error 1408)
contract MarketSlots is Market {
    constructor() Market(msg.sender, Rate.wrap(5e16), Ratio.wrap(80)) {}

    // 第120講: メモリに触れないブロック。sload・sstoreなし、欄の番号だけを取り出す
    function slotsOf()
        external
        pure
        returns (uint256 statusSlot, uint256 statusOffset, uint256 assetsSlot, uint256 configSlot, uint256 positionsSlot, uint256 depositsSlot, uint256 borrowsSlot)
    {
        assembly {
            statusSlot := status.slot
            statusOffset := status.offset
            assetsSlot := assets.slot
            configSlot := assetConfig.slot
            positionsSlot := positions.slot
            depositsSlot := totalDeposits.slot
            borrowsSlot := totalBorrows.slot
        }
    }

    // 第120講: storageローカル変数の.slotはコンパイラがkeccak256で求めた欄の番号
    function positionSlot(address asset, address user) external view returns (uint256 s) {
        Position storage p = positions[asset][user];
        assembly {
            s := p.slot
        }
    }
}

// 第120講: スロットマップに書いた番号とコンパイラが付けた番号が同じか
contract AssemblyTest is Test {
    MarketSlots market;
    MockToken token;

    function setUp() public {
        market = new MarketSlots();
        token = new MockToken();
    }

    // 第120講: スロットマップ 0 status、1 assets、2 assetConfig、3 positions、4 totalDeposits、5 totalBorrows
    function test_slotsMatchSlotMap() public view {
        (uint256 st, uint256 off, uint256 a, uint256 c, uint256 p, uint256 d, uint256 b) = market.slotsOf();
        assertEq(st, 0);
        assertEq(off, 0);
        assertEq(a, 1);
        assertEq(c, 2);
        assertEq(p, 3);
        assertEq(d, 4);
        assertEq(b, 5);
    }

    // 第120講: positions[asset][user]の.slotは第116講のテストが手で書いたkeccak256の式と同じ
    function test_positionSlotMatchesKeccak() public view {
        bytes32 byHand = keccak256(abi.encode(address(this), keccak256(abi.encode(address(token), uint256(3)))));
        assertEq(market.positionSlot(address(token), address(this)), uint256(byHand));
    }
}
