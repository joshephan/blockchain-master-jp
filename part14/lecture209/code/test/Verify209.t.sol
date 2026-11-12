// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base57} from "./Base57.sol";
import {Message, Msg, IVerifier} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";
import {ToyEndpoint} from "../src/Endpoint57.sol";
import {OptimisticVerifier, HeaderLightClient} from "../src/Verifiers57.sol";
import {PingSender, PingApp} from "../src/Ping57.sol";

// 第209講: 同じendpointに検証の席だけを差し替える。楽観的(待機と監視者)、ライトクライアントの小さい形(向こうのバリデーターの署名ヘッダーと証明)
contract VerifyTest is Base57 {
    ToyOutbox outboxA;
    PingSender sender;
    address proposer = makeAddr("proposer");
    address watcher = makeAddr("watcher");
    uint256[4] keys = [uint256(0xA11CE), 0xB0B, 0xC0FFEE, 0xD00D];
    uint256[4] nextKeys = [uint256(0xE1), 0xE2, 0xE3, 0xE4];

    function setUp() public {
        vm.chainId(A);
        outboxA = new ToyOutbox();
        sender = new PingSender(outboxA);
        vm.recordLogs();
    }

    function _stack(IVerifier v) internal returns (ToyEndpoint endpoint, PingApp app) {
        vm.chainId(B);
        endpoint = new ToyEndpoint(v, _one(A), _oneAddr(address(outboxA)));
        app = new PingApp(address(endpoint), A, address(sender));
    }

    function _ping(PingApp app, string memory text) internal returns (bytes32 id, Message memory m) {
        vm.chainId(A);
        sender.ping(B, address(app), text);
        (id, m) = _lastMessage();
        vm.chainId(B);
    }

    // ---- 楽観的検証 ----

    function _optimistic() internal returns (OptimisticVerifier v, ToyEndpoint endpoint, PingApp app) {
        vm.chainId(B);
        address[] memory w = _oneAddr(watcher);
        v = new OptimisticVerifier(proposer, w);
        (endpoint, app) = _stack(v);
    }

    function test_tooEarlyNotVerified() public {
        (OptimisticVerifier v, ToyEndpoint endpoint, PingApp app) = _optimistic();
        (bytes32 id, Message memory m) = _ping(app, "hello");
        vm.prank(proposer);
        v.propose(id);
        vm.warp(block.timestamp + 29 minutes);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.NotVerified.selector, id));
        endpoint.deliver(m, "");
    }

    function test_afterWindowVerified() public {
        (OptimisticVerifier v, ToyEndpoint endpoint, PingApp app) = _optimistic();
        (bytes32 id, Message memory m) = _ping(app, "hello");
        vm.prank(proposer);
        v.propose(id);
        vm.warp(block.timestamp + 30 minutes);
        endpoint.deliver(m, "");
        assertEq(app.count(), 1);
    }

    function test_watcherChallengeBlocks() public {
        (OptimisticVerifier v, ToyEndpoint endpoint, PingApp app) = _optimistic();
        (bytes32 id, Message memory m) = _ping(app, "hello");
        vm.prank(proposer);
        v.propose(id);
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(watcher);
        v.challenge(id);
        vm.warp(block.timestamp + 1 days);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.NotVerified.selector, id));
        endpoint.deliver(m, "");
    }

    function test_challengeClosedAfterWindow() public {
        (OptimisticVerifier v,, PingApp app) = _optimistic();
        (bytes32 id,) = _ping(app, "hello");
        vm.prank(proposer);
        v.propose(id);
        vm.warp(block.timestamp + 30 minutes);
        vm.prank(watcher);
        vm.expectRevert(abi.encodeWithSelector(OptimisticVerifier.ChallengeClosed.selector, id));
        v.challenge(id);
    }

    function test_strangerCannotChallenge() public {
        (OptimisticVerifier v,, PingApp app) = _optimistic();
        (bytes32 id,) = _ping(app, "hello");
        vm.prank(proposer);
        v.propose(id);
        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(OptimisticVerifier.NotWatcher.selector, stranger));
        v.challenge(id);
    }

    // ---- ライトクライアントの小さい形 ----

    function _addrs(uint256[4] storage ks) internal view returns (address[] memory a) {
        a = new address[](4);
        for (uint256 i = 0; i < 4; i++) {
            a[i] = vm.addr(ks[i]);
        }
    }

    // 選んだ鍵で署名。アドレスの昇順に並べる
    function _sign(bytes32 digest, uint256[] memory ks) internal pure returns (bytes[] memory sigs) {
        for (uint256 i = 0; i < ks.length; i++) {
            for (uint256 j = i + 1; j < ks.length; j++) {
                if (vm.addr(ks[j]) < vm.addr(ks[i])) (ks[i], ks[j]) = (ks[j], ks[i]);
            }
        }
        sigs = new bytes[](ks.length);
        for (uint256 i = 0; i < ks.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(ks[i], digest);
            sigs[i] = abi.encodePacked(r, s, v);
        }
    }

    function _pick(uint256[4] storage ks, uint256 n) internal view returns (uint256[] memory out) {
        out = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            out[i] = ks[i];
        }
    }

    function _leaf(bytes32 id) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(id))));
    }

    function _pair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encode(a, b)) : keccak256(abi.encode(b, a));
    }

    function _light()
        internal
        returns (
            HeaderLightClient lc,
            ToyEndpoint endpoint,
            PingApp app,
            Message memory m1,
            bytes32 root,
            bytes32 leaf2
        )
    {
        vm.chainId(B);
        lc = new HeaderLightClient(A, _addrs(keys));
        (endpoint, app) = _stack(lc);
        bytes32 id1;
        bytes32 id2;
        (id1, m1) = _ping(app, "hello");
        (id2,) = _ping(app, "world");
        leaf2 = _leaf(id2);
        root = _pair(_leaf(id1), leaf2);
    }

    function test_headerNeedsQuorum() public {
        (HeaderLightClient lc,,,, bytes32 root,) = _light();
        assertEq(lc.quorum(), 3);
        bytes[] memory sigs = _sign(lc.headerDigest(100, root), _pick(keys, 2));
        vm.expectRevert(abi.encodeWithSelector(HeaderLightClient.BelowQuorum.selector, 2, 3));
        lc.submitHeader(100, root, sigs);
    }

    function test_messageUnderHeaderDelivered() public {
        (HeaderLightClient lc, ToyEndpoint endpoint, PingApp app, Message memory m1, bytes32 root, bytes32 leaf2) =
            _light();
        lc.submitHeader(100, root, _sign(lc.headerDigest(100, root), _pick(keys, 3)));
        bytes32[] memory path = new bytes32[](1);
        path[0] = leaf2;
        endpoint.deliver(m1, abi.encode(uint256(100), path));
        assertEq(app.count(), 1);
        assertEq(app.last(), "hello");
    }

    function test_headerNotSubmittedRejected() public {
        (, ToyEndpoint endpoint,, Message memory m1,, bytes32 leaf2) = _light();
        bytes32[] memory path = new bytes32[](1);
        path[0] = leaf2;
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.NotVerified.selector, Msg.idOf(m1)));
        endpoint.deliver(m1, abi.encode(uint256(100), path));
    }

    function test_sameHeaderTwoClients() public {
        (HeaderLightClient lc,,,, bytes32 root,) = _light();
        bytes[] memory sigs = _sign(lc.headerDigest(100, root), _pick(keys, 3));
        vm.chainId(C);
        HeaderLightClient other = new HeaderLightClient(A, _addrs(keys));
        assertEq(other.headerDigest(100, root), lc.headerDigest(100, root));
        other.submitHeader(100, root, sigs);
        vm.chainId(B);
        lc.submitHeader(100, root, sigs);
        assertEq(other.messageRootOf(100), root);
        assertEq(lc.messageRootOf(100), root);
    }

    function test_rotationByCurrentSet() public {
        (HeaderLightClient lc,,,, bytes32 root,) = _light();
        address[] memory next = _addrs(nextKeys);
        lc.rotate(next, _sign(lc.setDigest(1, next), _pick(keys, 3)));
        assertEq(lc.epoch(), 1);
        uint256[] memory old3 = _pick(keys, 3);
        bytes[] memory oldSigs = _sign(lc.headerDigest(101, root), old3);
        vm.expectRevert(abi.encodeWithSelector(HeaderLightClient.NotValidator.selector, vm.addr(old3[0])));
        lc.submitHeader(101, root, oldSigs);
        lc.submitHeader(101, root, _sign(lc.headerDigest(101, root), _pick(nextKeys, 3)));
        assertEq(lc.messageRootOf(101), root);
    }
}
