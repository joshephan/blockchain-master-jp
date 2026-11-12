// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm, console} from "forge-std/Test.sol";
import {Nft} from "../src/Nft.sol";
import {Plain, Rejecter, WrongMagic, Acceptor, Burner, Prize} from "../src/Receivers.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/market/Market.sol";

contract CallbackTest is Test {
    Nft nft;
    address alice = address(0xA11CE);

    function setUp() public {
        nft = new Nft();
        for (uint256 i = 1; i <= 8; i++) {
            nft.mint(alice, i);
        }
    }

    function _safe(address to, uint256 id) internal returns (bool ok, bytes memory data) {
        vm.prank(alice);
        (ok, data) =
            address(nft).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, to, id));
    }

    function test_plainTransferFromStuck() public {
        Plain p = new Plain();
        vm.prank(alice);
        nft.transferFrom(alice, address(p), 1);
        assertEq(nft.ownerOf(1), address(p));
    }

    function test_plainSafeReverts() public {
        Plain p = new Plain();
        (bool ok, bytes memory data) = _safe(address(p), 1);
        assertFalse(ok);
        console.logBytes(data);
        assertEq(nft.ownerOf(1), alice);
    }

    function test_rejecter() public {
        Rejecter r = new Rejecter();
        (bool ok, bytes memory data) = _safe(address(r), 1);
        assertFalse(ok);
        console.logBytes(data);
        vm.prank(alice);
        nft.transferFrom(alice, address(r), 1);
        assertEq(nft.ownerOf(1), address(r));
    }

    function test_wrongMagic() public {
        WrongMagic w = new WrongMagic();
        (bool ok, bytes memory data) = _safe(address(w), 1);
        assertFalse(ok);
        console.logBytes(data);
    }

    function test_acceptorSeesNewOwner() public {
        Acceptor a = new Acceptor();
        (bool ok,) = _safe(address(a), 1);
        assertTrue(ok);
        assertEq(a.seenOwner(), address(a));
        assertEq(a.seenOperator(), alice);
        assertEq(a.seenFrom(), alice);
        assertEq(a.calls(), 1);
    }

    function test_burner() public {
        Burner b = new Burner();
        vm.prank(alice);
        (bool ok,) = address(nft).call{gas: 1_000_000}(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", alice, address(b), 1)
        );
        assertFalse(ok);
        assertEq(nft.ownerOf(1), alice);
    }

    function test_prizeBlockedByRejecter() public {
        Prize p = new Prize(IERC721(address(nft)), 2);
        vm.prank(alice);
        nft.transferFrom(alice, address(p), 2);
        Rejecter r = new Rejecter();
        vm.expectRevert(bytes("no thanks"));
        p.award(address(r));
        assertFalse(p.awarded());
        assertEq(nft.ownerOf(2), address(p));
        p.award(address(0xB0B));
        assertEq(nft.ownerOf(2), address(0xB0B));
    }

    // セレクター: ERC-20とERC-721が同じ4バイト
    function test_selectors() public pure {
        console.logBytes4(IERC721.transferFrom.selector);
        console.logBytes4(IERC20.transferFrom.selector);
        console.logBytes4(IERC721.balanceOf.selector);
        console.logBytes4(bytes4(keccak256("approve(address,uint256)")));
        console.logBytes4(bytes4(keccak256("safeTransferFrom(address,address,uint256)")));
        console.logBytes4(bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")));
        console.logBytes4(bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")));
    }

    // 同じtopic0、違う配置
    function test_transferLogShape() public {
        vm.recordLogs();
        vm.prank(alice);
        nft.transferFrom(alice, address(0xB0B), 3);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.log("logs", logs.length);
        console.log("topics", logs[0].topics.length, "data bytes", logs[0].data.length);
        console.logBytes32(logs[0].topics[0]);
        console.logBytes32(logs[0].topics[3]);
    }

    // MarketにNFTを上場すると: transferFromのセレクターは合うが、戻り値がないのでdeposit全体が巻き戻る
    function test_marketDepositNft() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(nft)), Ratio.wrap(75));
        vm.startPrank(alice);
        nft.approve(address(market), 4);
        (bool ok, bytes memory data) =
            address(market).call(abi.encodeWithSignature("deposit(address,uint256)", address(nft), 4));
        vm.stopPrank();
        assertFalse(ok);
        console.log("revert data bytes", data.length);
        assertEq(nft.ownerOf(4), alice);
        assertEq(Amount.unwrap(market.totalDeposits(address(nft))), 0);
    }

    // MarketにsafeTransferFrom: 受け取る関数がないので巻き戻る / transferFrom: Marketに入って取り出す道がない
    function test_marketReceivesNft() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        (bool ok, bytes memory data) = _safe(address(market), 5);
        assertFalse(ok);
        console.logBytes(data);
        vm.prank(alice);
        nft.transferFrom(alice, address(market), 5);
        assertEq(nft.ownerOf(5), address(market));
    }
}
