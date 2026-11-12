// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// UUPSの最初の版。アップグレード権限の確認が実装側の_authorizeUpgradeにある
contract BoxUUPS is Initializable, UUPSUpgradeable {
    address public owner;
    uint256 public value;

    function initialize(address owner_) external initializer {
        owner = owner_;
    }

    function set(uint256 v) external {
        value = v;
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(address) internal view virtual override {
        require(msg.sender == owner, "not owner");
    }
}

// UUPSの二つ目の版。配置は同じ、doubleを追加
contract BoxUUPSV2 is BoxUUPS {
    function double() external {
        value *= 2;
    }

    function version() external pure override returns (uint256) {
        return 2;
    }
}

// 権限の確認を空にした版。誰でもアップグレード
contract BoxOpen is BoxUUPS {
    function version() external pure override returns (uint256) {
        return 3;
    }

    function _authorizeUpgrade(address) internal pure override {}
}

// UUPSではない普通のコントラクト。proxiableUUIDなし
contract PlainBox {
    address public owner;
    uint256 public value;

    function version() external pure returns (uint256) {
        return 9;
    }
}

// proxiableUUIDは正しい値を返すが、アップグレード関数がない版
contract LockedBox {
    address public owner;
    uint256 public value;

    function proxiableUUID() external pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }

    function version() external pure returns (uint256) {
        return 4;
    }
}
