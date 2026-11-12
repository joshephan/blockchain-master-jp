// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base57} from "./Base57.sol";
import {Message, Msg} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";
import {ToyEndpoint} from "../src/Endpoint57.sol";
import {AttesterVerifier} from "../src/Verifiers57.sol";
import {PingSender, PingApp} from "../src/Ping57.sol";

// 第208講: 送る側はログだけ残す。入れる人(中継)と正しいと言う側(検証)は別。受け取るアプリはチェーン番号とアドレスを一緒に見る
contract MessageTest is Base57 {
    ToyOutbox outboxA;
    ToyOutbox outboxC;
    PingSender sender;
    AttesterVerifier verifier;
    ToyEndpoint endpoint;
    PingApp app;
    address attester = makeAddr("attester");
    address relayer = makeAddr("relayer");

    function setUp() public {
        vm.chainId(A);
        outboxA = new ToyOutbox();
        sender = new PingSender(outboxA);
        vm.chainId(C);
        outboxC = new ToyOutbox();
        vm.chainId(B);
        verifier = new AttesterVerifier(attester);
        uint256[] memory ids = new uint256[](2);
        ids[0] = A;
        ids[1] = C;
        address[] memory boxes = new address[](2);
        boxes[0] = address(outboxA);
        boxes[1] = address(outboxC);
        endpoint = new ToyEndpoint(verifier, ids, boxes);
        app = new PingApp(address(endpoint), A, address(sender));
        vm.recordLogs();
    }

    function _ping(string memory text) internal returns (bytes32 id, Message memory m) {
        vm.chainId(A);
        sender.ping(B, address(app), text);
        (id, m) = _lastMessage();
        vm.chainId(B);
    }

    function test_sendOnlyLogs() public {
        (bytes32 id,) = _ping("hello");
        assertTrue(outboxA.sent(id));
        assertEq(outboxA.nonce(), 1);
        assertEq(app.count(), 0);
        assertEq(endpoint.status(id), 0);
    }

    function test_deliverNeedsVerification() public {
        (bytes32 id, Message memory m) = _ping("hello");
        vm.prank(relayer);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.NotVerified.selector, id));
        endpoint.deliver(m, "");
    }

    function test_anyoneRelaysAfterAttest() public {
        (bytes32 id, Message memory m) = _ping("hello");
        vm.prank(attester);
        verifier.attest(id);
        vm.prank(relayer);
        endpoint.deliver(m, "");
        assertEq(app.count(), 1);
        assertEq(app.last(), "hello");
        assertEq(endpoint.status(id), 1);
    }

    function test_strangerCannotAttest() public {
        (bytes32 id,) = _ping("hello");
        vm.prank(relayer);
        vm.expectRevert(abi.encodeWithSelector(AttesterVerifier.NotAttester.selector, relayer));
        verifier.attest(id);
    }

    function test_deliverOnce() public {
        (bytes32 id, Message memory m) = _ping("hello");
        vm.prank(attester);
        verifier.attest(id);
        endpoint.deliver(m, "");
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.AlreadyDelivered.selector, id));
        endpoint.deliver(m, "");
        assertEq(app.count(), 1);
    }

    function test_wrongDestinationRejected() public {
        (bytes32 id, Message memory m) = _ping("hello");
        vm.prank(attester);
        verifier.attest(id);
        vm.chainId(C);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.WrongDestination.selector, B));
        endpoint.deliver(m, "");
    }

    function test_unknownSourceRejected() public {
        vm.chainId(A);
        ToyOutbox otherBox = new ToyOutbox();
        vm.prank(address(sender));
        otherBox.send(B, address(app), abi.encode("hello"));
        (bytes32 id, Message memory m) = _lastMessage();
        vm.chainId(B);
        vm.prank(attester);
        verifier.attest(id);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.UnknownSource.selector, A, address(otherBox)));
        endpoint.deliver(m, "");
    }

    function test_fieldSwapChangesId() public {
        (bytes32 id, Message memory m) = _ping("hello");
        vm.prank(attester);
        verifier.attest(id);
        m.payload = abi.encode("bye");
        bytes32 swapped = Msg.idOf(m);
        assertTrue(swapped != id);
        vm.expectRevert(abi.encodeWithSelector(ToyEndpoint.NotVerified.selector, swapped));
        endpoint.deliver(m, "");
    }

    function test_receiverFailureKeepsSent() public {
        (bytes32 id, Message memory m) = _ping("");
        vm.prank(attester);
        verifier.attest(id);
        vm.expectEmit(true, false, false, true, address(endpoint));
        emit ToyEndpoint.DeliveryFailed(id, abi.encodeWithSelector(PingApp.EmptyText.selector));
        endpoint.deliver(m, "");
        assertEq(endpoint.status(id), 2);
        assertEq(app.count(), 0);
        assertTrue(outboxA.sent(id));
    }

    function test_peerChecksChainAndAddress() public {
        vm.chainId(C);
        vm.prank(address(sender));
        outboxC.send(B, address(app), abi.encode("hello"));
        (bytes32 id, Message memory m) = _lastMessage();
        vm.chainId(B);
        vm.prank(attester);
        verifier.attest(id);
        vm.expectEmit(true, false, false, true, address(endpoint));
        emit ToyEndpoint.DeliveryFailed(id, abi.encodeWithSelector(PingApp.NotPeer.selector, C, address(sender)));
        endpoint.deliver(m, "");
        assertEq(app.count(), 0);
    }
}
