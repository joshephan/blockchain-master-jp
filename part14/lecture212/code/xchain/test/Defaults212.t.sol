// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base57} from "./Base57.sol";
import {Message} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";
import {ToyEndpoint} from "../src/Endpoint57.sol";
import {AttesterVerifier, OptimisticVerifier, HeaderLightClient} from "../src/Verifiers57.sol";

// 第212講: 受け取り側のデフォルト値は全部「受け取らない」。受け取り側のコントラクト(endpoint)は受け取るアプリのonMessage一つだけを呼ぶ
contract DefaultsTest is Base57 {
    address proposer = makeAddr("proposer");
    address attester = makeAddr("attester");

    function test_zeroIdNeverVerified() public {
        OptimisticVerifier v = new OptimisticVerifier(proposer, _oneAddr(proposer));
        assertFalse(v.verify(bytes32(0), ""));
        vm.warp(block.timestamp + 365 days);
        assertFalse(v.verify(bytes32(0), ""));
        vm.prank(proposer);
        vm.expectRevert(OptimisticVerifier.ZeroId.selector);
        v.propose(bytes32(0));
    }

    function test_unsubmittedHeaderNeverVerified() public {
        HeaderLightClient lc = new HeaderLightClient(A, _oneAddr(vm.addr(0xA11CE)));
        assertEq(lc.messageRootOf(999), bytes32(0));
        bytes32[] memory empty = new bytes32[](0);
        assertFalse(lc.verify(keccak256("any"), abi.encode(uint256(999), empty)));
        assertFalse(lc.verify(bytes32(0), abi.encode(uint256(999), empty)));
    }

    function test_defaultStatusNotDelivered() public {
        AttesterVerifier v = new AttesterVerifier(attester);
        ToyEndpoint endpoint = new ToyEndpoint(v, _one(A), _oneAddr(address(1)));
        bytes32 id = keccak256("never sent");
        assertEq(endpoint.status(id), 0);
        assertFalse(v.attested(id));
        assertFalse(v.verify(id, ""));
    }

    function test_endpointCallsOnlyOnMessage() public {
        vm.chainId(A);
        ToyOutbox outboxA = new ToyOutbox();
        vm.chainId(B);
        AttesterVerifier v = new AttesterVerifier(attester);
        ToyEndpoint endpoint = new ToyEndpoint(v, _one(A), _oneAddr(address(outboxA)));
        vm.recordLogs();
        vm.chainId(A);
        outboxA.send(B, address(v), abi.encodeCall(AttesterVerifier.attest, (keccak256("x"))));
        (bytes32 id, Message memory m) = _lastMessage();
        vm.chainId(B);
        vm.prank(attester);
        v.attest(id);
        endpoint.deliver(m, "");
        assertEq(endpoint.status(id), 2);
        assertFalse(v.attested(keccak256("x")));
    }
}
