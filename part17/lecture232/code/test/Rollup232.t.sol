// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyL2} from "../src/ToyL2.sol";
import {OptimisticRollup232} from "../src/OptimisticRollup232.sol";

contract Rollup232Test is Test {
    OptimisticRollup232 internal rollup;
    address internal proposer = makeAddr("proposer");
    address internal watcher = makeAddr("watcher");
    uint256[4] internal genesis = [uint256(100), 50, 0, 0];

    function setUp() public {
        vm.warp(1_000_000);
        rollup = new OptimisticRollup232(genesis);
        vm.deal(proposer, 10 ether);
        vm.deal(watcher, 1 ether);
    }

    function _batch() internal pure returns (bytes memory) {
        // alice(0) -> bob(1) 30, bob(1) -> carol(2) 20
        return bytes.concat(ToyL2.encodeTx(0, 1, 30), ToyL2.encodeTx(1, 2, 20));
    }

    function _rightRoot() internal view returns (bytes32) {
        uint256[4] memory b = genesis;
        return ToyL2.root(ToyL2.run(b, _batch()));
    }

    function _wrongRoot() internal pure returns (bytes32) {
        // バッチと合わない結果: bobの欄を300と書いたルート
        uint256[4] memory b = [uint256(70), 300, 20, 0];
        return ToyL2.root(b);
    }

    function test_batchBytes() public pure {
        assertEq(_batch().length, 20);
    }

    function test_honestFinalizesAfterWindow() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _rightRoot());
        vm.warp(block.timestamp + 59 minutes);
        vm.expectRevert(abi.encodeWithSelector(OptimisticRollup232.WindowOpen.selector, 1_000_000 + 1 hours));
        rollup.finalize();
        vm.warp(1_000_000 + 1 hours);
        rollup.finalize();
        assertEq(rollup.finalizedRoot(), _rightRoot());
        assertEq(proposer.balance, 10 ether);
    }

    function test_wrongRootChallenged() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _wrongRoot());
        vm.warp(block.timestamp + 10 minutes);
        uint256 g = gasleft();
        vm.prank(watcher);
        rollup.challenge(genesis, _batch());
        console.log("challenge gas (2 tx)", g - gasleft());
        assertFalse(rollup.hasPending());
        assertEq(rollup.finalizedRoot(), ToyL2.root(genesis));
        assertEq(watcher.balance, 2 ether);
        assertEq(proposer.balance, 9 ether);
    }

    function test_honestCannotBeChallenged() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _rightRoot());
        vm.prank(watcher);
        vm.expectRevert(OptimisticRollup232.RootMatches.selector);
        rollup.challenge(genesis, _batch());
    }

    function test_challengeNeedsSameData() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _wrongRoot());
        bytes memory other = bytes.concat(ToyL2.encodeTx(0, 1, 30));
        vm.prank(watcher);
        vm.expectRevert(OptimisticRollup232.BadBatch.selector);
        rollup.challenge(genesis, other);
    }

    function test_challengeNeedsPreState() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _wrongRoot());
        uint256[4] memory guess = [uint256(100), 50, 0, 1];
        vm.prank(watcher);
        vm.expectRevert(OptimisticRollup232.BadPreState.selector);
        rollup.challenge(guess, _batch());
    }

    function test_unwatchedWrongRootFinalizes() public {
        vm.prank(proposer);
        rollup.propose{value: 1 ether}(_batch(), _wrongRoot());
        vm.warp(1_000_000 + 1 hours);
        vm.prank(watcher);
        vm.expectRevert(abi.encodeWithSelector(OptimisticRollup232.WindowClosed.selector, 1_000_000 + 1 hours));
        rollup.challenge(genesis, _batch());
        rollup.finalize();
        assertEq(rollup.finalizedRoot(), _wrongRoot());
    }

    function test_bondRequired() public {
        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(OptimisticRollup232.BondRequired.selector, 0));
        rollup.propose(_batch(), _rightRoot());
    }

    function _bigBatch(uint256 n) internal pure returns (bytes memory b) {
        for (uint256 i; i < n; ++i) {
            b = bytes.concat(b, ToyL2.encodeTx(uint8(i % 2), uint8((i + 1) % 2), 1));
        }
    }

    function test_challengeGasGrows() public {
        uint256[3] memory sizes = [uint256(10), 100, 1000];
        for (uint256 k; k < 3; ++k) {
            OptimisticRollup232 r = new OptimisticRollup232(genesis);
            bytes memory b = _bigBatch(sizes[k]);
            vm.prank(proposer);
            r.propose{value: 1 ether}(b, _wrongRoot());
            uint256 g = gasleft();
            vm.prank(watcher);
            r.challenge(genesis, b);
            console.log("txs", sizes[k], "challenge gas", g - gasleft());
            vm.deal(watcher, 1 ether);
        }
    }
}
