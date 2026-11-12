// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

// EIP-1167のクローンを作るファクトリー(OZ Clones)
contract CloneMaker {
    event Cloned(address clone);

    function make(address impl) external returns (address c) {
        c = Clones.clone(impl);
        emit Cloned(c);
    }

    // saltを入れてCREATE2で作る。アドレスは作る前に計算される
    function makeAt(address impl, bytes32 salt) external returns (address c) {
        c = Clones.cloneDeterministic(impl, salt);
        emit Cloned(c);
    }

    function predict(address impl, bytes32 salt) external view returns (address) {
        return Clones.predictDeterministicAddress(impl, salt);
    }
}
