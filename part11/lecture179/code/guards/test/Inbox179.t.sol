// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyInbox} from "../src/Inbox179.sol";

contract Inbox179Test is Test {
    // テスト用の鍵三つ(ローカルのテストの中でだけ使う)
    uint256 k1 = 0xA11CE;
    uint256 k2 = 0xB0B;
    uint256 k3 = 0xC0FFEE;
    uint256 kOut = 0xBAD;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    ToyInbox inbox;
    bytes32 leafA;
    bytes32 leafB;
    bytes32 root;

    function setUp() public {
        address[] memory v = new address[](3);
        v[0] = vm.addr(k1);
        v[1] = vm.addr(k2);
        v[2] = vm.addr(k3);
        inbox = new ToyInbox(v, 2);
        leafA = inbox.leafOf(alice, 100, 1);
        leafB = inbox.leafOf(bob, 50, 2);
        root = _hashPair(leafA, leafB);
    }

    function _hashPair(bytes32 x, bytes32 y) internal pure returns (bytes32) {
        return x < y ? keccak256(abi.encode(x, y)) : keccak256(abi.encode(y, x));
    }

    function _sig(uint256 k, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(k, digest);
        return abi.encodePacked(r, s, v);
    }

    // 署名者のアドレスの昇順で署名をまとめる
    function _sorted(uint256 x, uint256 y, bytes32 digest) internal pure returns (bytes[] memory s) {
        s = new bytes[](2);
        if (vm.addr(x) < vm.addr(y)) {
            s[0] = _sig(x, digest);
            s[1] = _sig(y, digest);
        } else {
            s[0] = _sig(y, digest);
            s[1] = _sig(x, digest);
        }
    }

    function _proofA() internal view returns (bytes32[] memory p) {
        p = new bytes32[](1);
        p[0] = leafB;
    }

    function test_rootNeedsThreshold() public {
        bytes[] memory one = new bytes[](1);
        one[0] = _sig(k1, inbox.rootDigest(root));
        vm.expectRevert(abi.encodeWithSelector(ToyInbox.BelowThreshold.selector, 1));
        inbox.acceptRoot(root, one);
    }

    function test_outsiderSigRejected() public {
        bytes[] memory s = _sorted(k1, kOut, inbox.rootDigest(root));
        address outsider = vm.addr(kOut);
        vm.expectRevert(abi.encodeWithSelector(ToyInbox.NotValidator.selector, outsider));
        inbox.acceptRoot(root, s);
    }

    function test_sameSignerTwiceRejected() public {
        bytes32 digest = inbox.rootDigest(root);
        bytes[] memory s = new bytes[](2);
        s[0] = _sig(k1, digest);
        s[1] = _sig(k1, digest);
        vm.expectRevert(abi.encodeWithSelector(ToyInbox.SignersNotSorted.selector, vm.addr(k1)));
        inbox.acceptRoot(root, s);
    }

    // 別のチェーン番号(1)を入れて作った署名は、このチェーンでは別のアドレスに復元されるのでバリデーターではない
    function test_otherChainSigRejected() public {
        vm.chainId(1);
        bytes[] memory s = _sorted(k1, k2, inbox.rootDigest(root));
        vm.chainId(31337);
        vm.expectPartialRevert(ToyInbox.NotValidator.selector);
        inbox.acceptRoot(root, s);
        assertFalse(inbox.acceptedRoot(root));
    }

    function test_unknownRootRejected() public {
        bytes32[] memory p = _proofA();
        vm.expectRevert(abi.encodeWithSelector(ToyInbox.UnknownRoot.selector, root));
        inbox.release(alice, 100, 1, root, p);
    }

    function test_releaseOnce() public {
        inbox.acceptRoot(root, _sorted(k1, k2, inbox.rootDigest(root)));
        bytes32[] memory p = _proofA();
        inbox.release(alice, 100, 1, root, p);
        assertEq(inbox.released(alice), 100);
        vm.expectRevert(abi.encodeWithSelector(ToyInbox.AlreadyProcessed.selector, leafA));
        inbox.release(alice, 100, 1, root, p);
    }

    // ルートにない金額は証明が合わない
    function test_wrongAmountRejected() public {
        inbox.acceptRoot(root, _sorted(k1, k3, inbox.rootDigest(root)));
        bytes32[] memory p = _proofA();
        vm.expectRevert(ToyInbox.BadProof.selector);
        inbox.release(alice, 1000, 1, root, p);
    }
}
