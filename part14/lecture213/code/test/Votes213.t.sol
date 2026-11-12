// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// 委任とチェックポイント: 票は誰に預けたかに従って動く
contract Votes213Test is Test {
    GovToken token;
    uint256 aliceKey = 0xA11CE;
    address alice;
    address carol = address(0xCA201);
    address dave = address(0xDA7E);
    address erin = address(0xE121);

    bytes32 constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    function setUp() public {
        alice = vm.addr(aliceKey);
        token = new GovToken(1000);
        token.transfer(alice, 100);
        vm.roll(10);
    }

    function test_delegateToOther() public {
        vm.prank(alice);
        token.delegate(dave);
        assertEq(token.delegates(alice), dave);
        assertEq(token.getVotes(dave), 100);
        assertEq(token.getVotes(alice), 0);
        assertEq(token.balanceOf(alice), 100);
        assertEq(token.balanceOf(dave), 0);
        // 票を預かった人もトークンは動かせない
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, dave, 0, 100));
        token.transferFrom(alice, dave, 100);
    }

    function test_votesFollowTransfer() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(alice);
        token.transfer(carol, 40); // carolは委任していない
        assertEq(token.getVotes(alice), 60);
        assertEq(token.getVotes(carol), 0);
        assertEq(token.delegates(carol), address(0));
        vm.roll(11);
        assertEq(token.getPastTotalSupply(10), 1000); // 委任していない分も全体の票数に入る
    }

    function test_transferToDelegatedMovesVotes() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(carol);
        token.delegate(dave); // 残高0のcarolが先にdaveに預けておく
        vm.prank(alice);
        token.transfer(carol, 40);
        assertEq(token.getVotes(alice), 60);
        assertEq(token.getVotes(dave), 40);
    }

    function test_redelegateMovesAll() public {
        vm.prank(alice);
        token.delegate(dave);
        vm.prank(alice);
        token.delegate(erin);
        assertEq(token.getVotes(dave), 0);
        assertEq(token.getVotes(erin), 100);
    }

    function test_checkpointsPerBlock() public {
        vm.prank(alice);
        token.delegate(alice); // ブロック10: 100
        vm.roll(11);
        vm.prank(alice);
        token.transfer(carol, 40); // ブロック11: 60
        vm.prank(alice);
        token.transfer(carol, 10); // 同じブロック11: 50、欄を新しく作らず書き直す
        vm.roll(12);
        assertEq(token.numCheckpoints(alice), 2);
        Checkpoints.Checkpoint208 memory c0 = token.checkpoints(alice, 0);
        Checkpoints.Checkpoint208 memory c1 = token.checkpoints(alice, 1);
        assertEq(c0._key, 10);
        assertEq(c0._value, 100);
        assertEq(c1._key, 11);
        assertEq(c1._value, 50);
        assertEq(token.getPastVotes(alice, 10), 100);
        assertEq(token.getPastVotes(alice, 11), 50);
        vm.expectRevert(abi.encodeWithSelector(Votes.ERC5805FutureLookup.selector, 12, 12));
        token.getPastVotes(alice, 12);
    }

    function test_delegateBySig() public {
        uint256 expiry = vm.getBlockTimestamp() + 1 days;
        (uint8 v, bytes32 r, bytes32 s) = _signDelegation(dave, 0, expiry);
        token.delegateBySig(dave, 0, expiry, v, r, s); // 誰が送っても署名したaliceの委任
        assertEq(token.delegates(alice), dave);
        assertEq(token.nonces(alice), 1);
        // 同じ署名をもう一度: 使用番号がもう1
        vm.expectRevert(abi.encodeWithSelector(Nonces.InvalidAccountNonce.selector, alice, 1));
        token.delegateBySig(dave, 0, expiry, v, r, s);
    }

    function test_delegateBySigExpired() public {
        uint256 expiry = vm.getBlockTimestamp() + 1 days;
        (uint8 v, bytes32 r, bytes32 s) = _signDelegation(dave, 0, expiry);
        vm.warp(expiry + 1);
        vm.expectRevert(abi.encodeWithSelector(IVotes.VotesExpiredSignature.selector, expiry));
        token.delegateBySig(dave, 0, expiry, v, r, s);
    }

    function test_transferGas() public {
        // 委任していない二つのアカウント間の送金
        token.transfer(carol, 100);
        vm.prank(carol);
        uint256 g0 = gasleft();
        token.transfer(erin, 10);
        uint256 plain = g0 - gasleft();
        // 両方とも自分に委任したアカウント間の送金: チェックポイントの欄を二つ直す
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(dave);
        token.delegate(dave);
        vm.roll(11);
        vm.prank(alice);
        g0 = gasleft();
        token.transfer(dave, 10);
        uint256 withVotes = g0 - gasleft();
        emit log_named_uint("transfer, no delegation", plain);
        emit log_named_uint("transfer, both delegated", withVotes);
        assertGt(withVotes, plain);
    }

    function test_clockMode() public view {
        assertEq(token.CLOCK_MODE(), "mode=blocknumber&from=default");
        assertEq(token.clock(), 10);
    }

    function test_supplyCap() public {
        vm.expectRevert(abi.encodeWithSelector(ERC20Votes.ERC20ExceededSafeSupply.selector, uint256(2) ** 208, uint256(2) ** 208 - 1));
        new GovToken(uint256(2) ** 208);
    }

    function _signDelegation(address to, uint256 n, uint256 expiry) internal view returns (uint8, bytes32, bytes32) {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, to, n, expiry));
        (, string memory name, string memory version, uint256 chainId, address verifying,,) = token.eip712Domain();
        bytes32 domain = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifying
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
        return vm.sign(aliceKey, digest);
    }
}
