// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Escrow51, IToken51} from "../src/Escrow51.sol";
import {EscrowFixed51} from "../src/EscrowFixed51.sol";

// テスト用トークン: 承認なしで移す
contract Token51 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address from, address to, uint256 a) external returns (bool) {
        balanceOf[from] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        return true;
    }
}

contract Escrow51Test is Test {
    Token51 t;
    address buyer = address(0xB);
    address seller = address(0x5);
    uint256 constant DEADLINE = 1_000_000;

    function setUp() public {
        t = new Token51();
        t.mint(buyer, 100);
        vm.warp(500_000);
    }

    // 正常な道: 確認すると販売者が100を引き出す
    function test_releaseAfterConfirm() public {
        Escrow51 e = new Escrow51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.startPrank(buyer);
        e.fund(100);
        e.confirm();
        vm.stopPrank();
        vm.prank(seller);
        e.release();
        assertEq(t.balanceOf(seller), 100);
    }

    // 正常な道: 確認なしで締め切りが過ぎると購入者が払い戻しを受ける
    function test_refundWithoutConfirm() public {
        Escrow51 e = new Escrow51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.prank(buyer);
        e.fund(100);
        vm.warp(DEADLINE + 1);
        vm.prank(buyer);
        e.refund();
        assertEq(t.balanceOf(buyer), 100);
    }

    // 見つけた問題: 確認した後でも締め切りが過ぎると払い戻しを受けられ、販売者のreleaseはAlreadySettled
    function test_refundAfterConfirm() public {
        Escrow51 e = new Escrow51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.startPrank(buyer);
        e.fund(100);
        e.confirm();
        vm.stopPrank();
        vm.warp(DEADLINE + 1);
        vm.prank(buyer);
        e.refund();
        vm.prank(seller);
        vm.expectRevert(Escrow51.AlreadySettled.selector);
        e.release();
        assertEq(t.balanceOf(buyer), 100);
        assertEq(t.balanceOf(seller), 0);
    }

    // 直した版: 確認後のrefundはAlreadyConfirmed、販売者は締め切り後でも100を引き出す
    function test_fixedRefundAfterConfirmReverts() public {
        EscrowFixed51 e = new EscrowFixed51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.startPrank(buyer);
        e.fund(100);
        e.confirm();
        vm.stopPrank();
        vm.warp(DEADLINE + 1);
        vm.prank(buyer);
        vm.expectRevert(EscrowFixed51.AlreadyConfirmed.selector);
        e.refund();
        vm.prank(seller);
        e.release();
        assertEq(t.balanceOf(seller), 100);
    }

    // 直した版でも正常な道はそのまま
    function test_fixedRefundWithoutConfirm() public {
        EscrowFixed51 e = new EscrowFixed51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.prank(buyer);
        e.fund(100);
        vm.warp(DEADLINE + 1);
        vm.prank(buyer);
        e.refund();
        assertEq(t.balanceOf(buyer), 100);
    }

    // 締め切りの時刻ちょうどのその秒には、まだ払い戻しを受けられない(TooEarly)。仕様どおり
    function test_refundAtDeadlineTooEarly() public {
        Escrow51 e = new Escrow51(IToken51(address(t)), buyer, seller, DEADLINE);
        vm.prank(buyer);
        e.fund(100);
        vm.warp(DEADLINE);
        vm.prank(buyer);
        vm.expectRevert(Escrow51.TooEarly.selector);
        e.refund();
    }
}
