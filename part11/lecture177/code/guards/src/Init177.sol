// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// プロキシの後ろに置く実装。オーナーはコンストラクタではなくinitializeが決める
contract CounterV1 is Initializable, UUPSUpgradeable {
    error NotOwner(address caller);

    address public owner;
    uint256 public count;

    // 実装アドレス自身の初期化をデプロイ時にロック
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_) external initializer {
        owner = owner_;
    }

    function inc() external {
        count += 1;
    }

    // アップグレード権限の確認。この関数が空だと誰でも変えられる
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != owner) revert NotOwner(msg.sender);
    }
}

contract CounterV2 is CounterV1 {
    function version() external pure returns (uint256) {
        return 2;
    }
}
