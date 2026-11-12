// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm, console} from "forge-std/Test.sol";
import {Multi, NoHook} from "../src/Multi.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/market/Market.sol";

contract Holder is ERC1155Holder {}

contract BatchTest is Test {
    Multi m;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        m = new Multi();
        m.mintRange(alice, 5, 100);
    }

    function _ids(uint256 n) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = i + 1;
        }
    }

    function _vals(uint256 n, uint256 v) internal pure returns (uint256[] memory vals) {
        vals = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            vals[i] = v;
        }
    }

    // 一つでも足りなければ、まとめて全体が巻き戻る
    function test_batchAllOrNothing() public {
        uint256[] memory vals = _vals(5, 10);
        vals[4] = 101;
        vm.prank(alice);
        (bool ok, bytes memory data) = address(m).call(
            abi.encodeWithSignature(
                "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)", alice, bob, _ids(5), vals, ""
            )
        );
        assertFalse(ok);
        console.logBytes(data);
        assertEq(m.balanceOf(bob, 1), 0);
        assertEq(m.balanceOf(alice, 1), 100);
    }

    // 受け取る関数のないコントラクトには、どんな移転もできない(transferFromのような形が標準にない)
    function test_noHookReverts() public {
        NoHook n = new NoHook();
        vm.prank(alice);
        (bool ok, bytes memory data) = address(m).call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)", alice, address(n), 1, 10, ""
            )
        );
        assertFalse(ok);
        console.logBytes(data);
        Holder h = new Holder();
        vm.prank(alice);
        m.safeTransferFrom(alice, address(h), 1, 10, "");
        assertEq(m.balanceOf(address(h), 1), 10);
    }

    // 承認はオペレーター単位で、全部かゼロか
    function test_operatorAll() public {
        vm.prank(alice);
        m.setApprovalForAll(bob, true);
        vm.prank(bob);
        m.safeBatchTransferFrom(alice, bob, _ids(5), _vals(5, 100), "");
        for (uint256 i = 1; i <= 5; i++) {
            assertEq(m.balanceOf(bob, i), 100);
        }
    }

    function test_batchLog() public {
        vm.recordLogs();
        vm.prank(alice);
        m.safeBatchTransferFrom(alice, bob, _ids(5), _vals(5, 1), "");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.log("logs", logs.length, "topics", logs[0].topics.length);
        console.log("data bytes", logs[0].data.length);
        console.logBytes32(logs[0].topics[0]);
        vm.recordLogs();
        vm.prank(alice);
        m.safeTransferFrom(alice, bob, 1, 1, "");
        logs = vm.getRecordedLogs();
        console.log("single data bytes", logs[0].data.length);
        console.logBytes32(logs[0].topics[0]);
    }

    function test_balanceOfBatch() public view {
        address[] memory who = new address[](3);
        who[0] = alice;
        who[1] = alice;
        who[2] = bob;
        uint256[] memory ids = new uint256[](3);
        ids[0] = 1;
        ids[1] = 5;
        ids[2] = 1;
        uint256[] memory b = m.balanceOfBatch(who, ids);
        console.log(b[0], b[1], b[2]);
    }

    function test_selectors() public pure {
        console.logBytes4(bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")));
        console.logBytes4(bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")));
        console.logBytes4(bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")));
        console.logBytes4(bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")));
        console.logBytes4(bytes4(keccak256("balanceOf(address,uint256)")));
    }

    // MarketにERC-1155のアドレスを上場すると: transferFrom(address,address,uint256)がないのでdepositが巻き戻る
    function test_marketDeposit1155() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(m)), Ratio.wrap(75));
        vm.startPrank(alice);
        m.setApprovalForAll(address(market), true);
        (bool ok, bytes memory data) =
            address(market).call(abi.encodeWithSignature("deposit(address,uint256)", address(m), 1));
        vm.stopPrank();
        assertFalse(ok);
        console.log("revert data bytes", data.length);
    }
}
