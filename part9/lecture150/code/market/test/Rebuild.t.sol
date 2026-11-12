// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// Marketとまったく同じシグネチャのイベントを出す任意のコントラクト
contract LookAlike {
    event Deposited(address indexed asset, address indexed user, uint256 amount);

    function fake(address asset, address user, uint256 amount) external {
        emit Deposited(asset, user, amount);
    }
}

// 出力してから巻き戻るコントラクト
contract Thrower {
    event Tried(uint256 n);

    function tryIt(uint256 n) external {
        emit Tried(n);
        revert("no");
    }
}

// 第107講: 読む側の真似。ログだけでユーザーごとの預け入れ額を組み立て直し、Marketのpositionsと照合
contract RebuildTest is Test {
    MockToken token;
    Market market;
    LookAlike look;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        look = new LookAlike();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 300);
        token.transfer(bob, 300);
    }

    function _play() internal returns (Vm.Log[] memory) {
        vm.recordLogs();
        vm.prank(alice);
        market.deposit(address(token), 200);
        vm.prank(bob);
        market.deposit(address(token), 100);
        vm.prank(alice);
        market.withdraw(address(token), 50);
        look.fake(address(token), bob, 1000);
        return vm.getRecordedLogs();
    }

    function _rebuild(Vm.Log[] memory logs, address user, bool checkEmitter) internal view returns (uint256 sum) {
        for (uint256 i = 0; i < logs.length; i++) {
            Vm.Log memory l = logs[i];
            if (checkEmitter && l.emitter != address(market)) continue;
            if (l.topics.length != 3 || l.topics[2] != bytes32(uint256(uint160(user)))) continue;
            if (l.topics[0] == IMarket.Deposited.selector) sum += abi.decode(l.data, (uint256));
            if (l.topics[0] == IMarket.Withdrawn.selector) sum -= abi.decode(l.data, (uint256));
        }
    }

    function test_rebuildMatchesPositions() public {
        Vm.Log[] memory logs = _play();
        (Amount a,,,) = market.positions(address(token), alice);
        (Amount b,,,) = market.positions(address(token), bob);
        assertEq(_rebuild(logs, alice, true), Amount.unwrap(a)); // 150
        assertEq(_rebuild(logs, bob, true), Amount.unwrap(b)); // 100
    }

    // アドレスで絞らないと、LookAlikeが出したログまでMarketのものとして数える
    function test_withoutEmitterCheck() public {
        Vm.Log[] memory logs = _play();
        assertEq(_rebuild(logs, bob, false), 1100);
    }

    // vm.getRecordedLogsは巻き戻った呼び出しのログも返す。チェーンのレシートにはこのログはない
    function test_recordedLogsIncludeReverted() public {
        Thrower t = new Thrower();
        vm.recordLogs();
        try t.tryIt(5) {} catch {}
        assertEq(vm.getRecordedLogs().length, 1);
    }
}
