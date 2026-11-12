// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ToyL2} from "./ToyL2.sol";

/// 講義用の脱出の道: オペレーターが決めておいた期間ルートを上げなければ凍結し、
/// そのときから各自が最後のルートの下の自分の残高を証明してL1で取り戻す
/// ルートを受け取る側の検証(異議申し立てや証明の確認)は省いた
contract Exit233 {
    uint256 public constant FREEZE = 7 days; // 講義用の凍結までの期間

    address public immutable operator;
    address[4] public owners;
    bytes32 public root;
    uint64 public updatedAt;
    mapping(uint256 => bool) public exited;

    event RootUpdated(bytes32 root);
    event Escaped(uint256 indexed index, address indexed to, uint256 amount);

    error NotOperator(address caller);
    error IsFrozen();
    error NotFrozen(uint256 freezesAt);
    error AlreadyExited(uint256 index);
    error BadProof();
    error PayFailed(address to);

    constructor(address operator_, address[4] memory owners_, bytes32 root_) payable {
        operator = operator_;
        owners = owners_;
        root = root_;
        updatedAt = uint64(block.timestamp);
    }

    function frozen() public view returns (bool) {
        return block.timestamp >= updatedAt + FREEZE;
    }

    function update(bytes32 newRoot) external {
        if (msg.sender != operator) revert NotOperator(msg.sender);
        if (frozen()) revert IsFrozen();
        root = newRoot;
        updatedAt = uint64(block.timestamp);
        emit RootUpdated(newRoot);
    }

    /// 凍結したあと欄ごとに一度、証明した残高の分をその欄の持ち主に送る
    function escape(uint256 i, uint256 amount, bytes32[2] calldata proof) external {
        if (!frozen()) revert NotFrozen(updatedAt + FREEZE);
        if (exited[i]) revert AlreadyExited(i);
        if (!ToyL2.verify(root, i, amount, proof)) revert BadProof();
        exited[i] = true;
        address to = owners[i];
        emit Escaped(i, to, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PayFailed(to);
    }
}
