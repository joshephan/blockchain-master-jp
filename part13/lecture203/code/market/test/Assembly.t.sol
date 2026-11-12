// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, stdError} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount, Position} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol"; // 第122講
import {MockToken} from "../src/MockToken.sol";

// 第123講: NoAssemblyTestを追加(interestForがあふれるとPanic 0x11)
// 第122講: RawCaller・RawCallTestを追加(手でかけたstaticcall・callと巻き戻りデータを上に送る)
// 第120講: アセンブリの.slot・.offsetでスロットマップを確認するテスト用コントラクト。デプロイ物のMarketにはアセンブリなし
// Marketを継承するので状態変数の名前が見える。状態変数は名前だけでは使えない(Error 1408)
contract MarketSlots is Market {
    constructor() Market(msg.sender, Rate.wrap(5e16), Ratio.wrap(80)) {}

    // 第120講: メモリに触れないブロック。sload・sstoreなし、欄の番号だけを取り出す
    function slotsOf()
        external
        pure
        returns (
            uint256 statusSlot,
            uint256 statusOffset,
            uint256 assetsSlot,
            uint256 configSlot,
            uint256 positionsSlot,
            uint256 depositsSlot,
            uint256 borrowsSlot
        )
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

// 第122講: 低水準の呼び出しでMarketを呼ぶテスト用コントラクト。デプロイ物のMarketにはアセンブリなし
contract RawCaller {
    // 第122講: staticcall(ガス, アドレス, 入力の位置, 入力の長さ, 出力の位置, 出力の長さ)。成功すれば1、失敗すれば0
    function statusOf(address m) external view returns (uint256 ok, uint256 st) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x200d2ed2)) // status()
            ok := staticcall(gas(), m, p, 4, p, 0x20)
            st := mload(p)
        }
    }

    // 第122講: 失敗しても巻き戻らず0が返ってくる。巻き戻りデータはreturndatasize・returndatacopyで直接取ってくる
    function depositRaw(address m, address asset, uint256 amount)
        external
        returns (uint256 ok, uint256 size, bytes4 sel)
    {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x47e7ef24)) // deposit(address,uint256)
            mstore(add(p, 4), asset)
            mstore(add(p, 0x24), amount)
            ok := call(gas(), m, 0, p, 0x44, 0, 0)
            size := returndatasize()
            returndatacopy(p, 0, size)
            sel := mload(p)
            mstore(0x40, add(p, and(add(size, 0x3f), not(0x1f)))) // 第121講: 書いた分だけ0x40を動かす
        }
    }

    // 第122講: 受け取った巻き戻りデータをそのまま上に送る。Solidityの文法だけではbytesを巻き戻りデータとして投げられない
    function depositOrBubble(address m, address asset, uint256 amount) external {
        (bool ok, bytes memory data) = m.call(abi.encodeWithSignature("deposit(address,uint256)", asset, amount));
        if (!ok) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
    }
}

// 第122講: アセンブリでかけた呼び出しがMarketのエラーをバイト列で受け取り、そのまま上に送るか
contract RawCallTest is Test {
    Market market;
    MockToken token;
    RawCaller raw;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        token = new MockToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        raw = new RawCaller();
    }

    // 第122講: status()はスロット0。Activeなら0
    function test_rawStaticcallReadsStatus() public view {
        (uint256 ok, uint256 st) = raw.statusOf(address(market));
        assertEq(ok, 1);
        assertEq(st, 0);
    }

    // 第122講: 0を預けるとMarketはZeroAmountで巻き戻す。手でかけたcallは0と4バイトを受け取り、そのまま進む
    function test_rawCallGetsErrorBytes() public {
        (uint256 ok, uint256 size, bytes4 sel) = raw.depositRaw(address(market), address(token), 0);
        assertEq(ok, 0);
        assertEq(size, 4);
        assertEq(sel, IMarket.ZeroAmount.selector);
    }

    // 第122講: 上に送ったデータがMarketが巻き戻したものと同じ
    function test_bubbleKeepsMarketError() public {
        vm.expectRevert(IMarket.ZeroAmount.selector);
        raw.depositOrBubble(address(market), address(token), 0);
    }
}

// 第123講: Marketにアセンブリを入れないことにした根拠の一つをテストで残す
// interestForの本体をアセンブリのmul・divに変えた版では、このテストが失敗する
contract NoAssemblyTest is Test {
    Market market;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 第123講: あふれる入力では間違った値を返さず、Panic 0x11で巻き戻す
    function test_interestForOverflowPanics() public {
        vm.expectRevert(stdError.arithmeticError);
        market.interestFor(2 ** 200, Rate.wrap(5e16), 365 days);
    }
}
