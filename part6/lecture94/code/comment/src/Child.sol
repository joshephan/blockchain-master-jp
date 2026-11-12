// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Child {
    // コンストラクタで受け取った値
    uint256 public x;

    constructor(uint256 _x) {
        require(_x != 0, "x is zero");
        x = _x;
    }
}

contract PayChild {
    uint256 public x;

    constructor(uint256 _x) payable {
        x = _x;
    }
}

contract Factory {
    uint256 public made;

    function make(uint256 x) external returns (Child) {
        made += 1;
        Child c = new Child(x);
        return c;
    }

    function makeSalted(bytes32 salt, uint256 x) external returns (Child) {
        made += 1;
        return new Child{salt: salt}(x);
    }

    function makePaid(uint256 x) external payable returns (PayChild) {
        return new PayChild{value: msg.value}(x);
    }

    // 機械命令createを直接呼ぶ
    function rawCreate(uint256 x) external returns (address a) {
        bytes memory initCode = abi.encodePacked(type(Child).creationCode, abi.encode(x));
        assembly {
            a := create(0, add(initCode, 0x20), mload(initCode))
        }
    }
}
