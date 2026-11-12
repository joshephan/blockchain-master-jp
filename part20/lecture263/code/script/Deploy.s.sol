// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Market} from "../src/Market.sol";

// デプロイの順番(設計文書14節): タイムロック → Market。マルチシグは先にある必要がある(アドレスを受け取る)
// デプロイアカウントはどのロールも受け取らない(タイムロックのコンストラクタのadmin引数は0)。資産の上場はこのスクリプトにない(マルチシグがタイムロックに予約)
contract Deploy is Script {
    /// @notice タイムロックの最小待機(設計値、D-13)
    uint256 public constant MIN_DELAY = 2 days;
    /// @notice 折れ点の年利率5%(倍率10の18乗)
    uint256 public constant RATE_AT_KINK = 0.05e18;
    /// @notice マルチシグに求める最小のしきい値
    uint256 public constant MIN_THRESHOLD = 2;

    error CheckFailed(string what);

    /// @notice COUNCIL(マルチシグのアドレス)を環境変数で受け取ってデプロイし、同じ実行の中で確認リストを回す
    function run() external returns (TimelockController timelock, Market market) {
        address council = vm.envAddress("COUNCIL");
        checkCouncil(council);
        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();
        (timelock, market) = deploy(council);
        vm.stopBroadcast();
        check(timelock, market, council, deployer);
    }

    /// @notice デプロイ二件。タイムロックが先(Marketのコンストラクタがそのアドレスを受け取る)
    function deploy(address council) public returns (TimelockController timelock, Market market) {
        address[] memory roles = new address[](1);
        roles[0] = council;
        timelock = new TimelockController(MIN_DELAY, roles, roles, address(0));
        market = new Market(address(timelock), council, RATE_AT_KINK);
    }

    /// @notice 送る前の確認: マルチシグの席にコードがあり、しきい値が二以上
    function checkCouncil(address council) public view {
        if (council.code.length == 0) revert CheckFailed("council has no code");
        (bool ok, bytes memory ret) = council.staticcall(abi.encodeWithSignature("threshold()"));
        if (!ok || ret.length != 32 || abi.decode(ret, (uint256)) < MIN_THRESHOLD) {
            revert CheckFailed("council threshold");
        }
    }

    /// @notice 送ったあとの確認: 席ごとに座ったアドレスと残ったロール
    function check(TimelockController timelock, Market market, address council, address deployer) public view {
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();
        if (market.admin() != address(timelock)) revert CheckFailed("market admin");
        if (market.guardian() != council) revert CheckFailed("market guardian");
        if (market.rateAtKink() != RATE_AT_KINK) revert CheckFailed("rate at kink");
        if (market.assetCount() != 0) revert CheckFailed("asset count");
        if (timelock.getMinDelay() != MIN_DELAY) revert CheckFailed("min delay");
        if (!timelock.hasRole(adminRole, address(timelock))) revert CheckFailed("timelock self admin");
        if (timelock.hasRole(adminRole, deployer)) revert CheckFailed("deployer admin");
        if (timelock.hasRole(timelock.PROPOSER_ROLE(), deployer)) revert CheckFailed("deployer proposer");
        if (timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0))) revert CheckFailed("open executor");
        if (!timelock.hasRole(timelock.PROPOSER_ROLE(), council)) revert CheckFailed("council proposer");
        if (!timelock.hasRole(timelock.CANCELLER_ROLE(), council)) revert CheckFailed("council canceller");
        if (!timelock.hasRole(timelock.EXECUTOR_ROLE(), council)) revert CheckFailed("council executor");
    }
}
