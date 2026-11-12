// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {Market, AssetRegistry, Ledger, MarketBase, IERC20, Ratio, Rate} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第106講: topics[0]はイベントのシグネチャ全体のkeccak256の32バイト、indexed引数はtopics[1]から、残りはdata
contract TopicsTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    // シグネチャにはindexedも引数名も入らない。RatioとenumはABI型uint8として書かれる
    function test_topic0ByHand() public pure {
        assertEq(Ledger.Deposited.selector, keccak256("Deposited(address,address,uint256)"));
        assertEq(Ledger.Withdrawn.selector, keccak256("Withdrawn(address,address,uint256)"));
        assertEq(AssetRegistry.AssetAdded.selector, keccak256("AssetAdded(address,uint8)"));
        assertEq(MarketBase.StatusChanged.selector, keccak256("StatusChanged(uint8,uint8)"));
    }

    function test_depositTopics() public {
        vm.recordLogs();
        market.deposit(address(token), 100);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1);
        assertEq(logs[0].emitter, address(market));
        assertEq(logs[0].topics.length, 3);
        assertEq(logs[0].topics[0], Ledger.Deposited.selector);
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(address(token)))));
        assertEq(logs[0].topics[2], bytes32(uint256(uint160(address(this)))));
        assertEq(abi.decode(logs[0].data, (uint256)), 100);
    }
}
