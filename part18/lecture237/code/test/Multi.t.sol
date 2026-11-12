// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";

// 第157講: ERC-1155の残高の欄と移転一つだけを書いたテスト用トークン。残高は(アドレス, id)の二重、transferFrom(address,address,uint256)なし
contract MiniMulti {
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function mint(address to, uint256 id, uint256 value) external {
        balanceOf[to][id] += value;
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata) external {
        require(from == msg.sender || isApprovedForAll[from][msg.sender], "not allowed");
        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;
    }
}

// 第157講: Marketの資産の欄はアドレス一つがトークン一つ。ERC-1155のアドレスを上場すると、Marketが呼ぶtransferFromがないので巻き戻る
contract MultiTest is Test {
    function test_multiDepositReverts() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        MiniMulti multi = new MiniMulti();
        address alice = address(0xA11CE);
        multi.mint(alice, 1, 100);
        market.addAsset(IERC20(address(multi)), Ratio.wrap(75));
        vm.startPrank(alice);
        multi.setApprovalForAll(address(market), true);
        (bool ok, bytes memory data) =
            address(market).call(abi.encodeWithSignature("deposit(address,uint256)", address(multi), 100));
        vm.stopPrank();
        assertFalse(ok);
        assertEq(data.length, 0);
        assertEq(multi.balanceOf(alice, 1), 100);
        assertEq(Amount.unwrap(market.totalDeposits(address(multi))), 0);
    }
}
