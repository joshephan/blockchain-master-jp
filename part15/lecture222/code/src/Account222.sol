// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IAccount, ValidationData} from "./UserOp.sol";

// 講義用のセッションキーアカウント。持ち主の鍵は全部、セッションキーは記録した範囲だけ
// 範囲: コントラクト一つ、関数一つ、最初の引数(資産)一つ、合計の上限、開始・終了時刻、自分のナンスの列
contract Account222 is IAccount {
    struct Session {
        address target;
        bytes4 selector;
        address asset;
        uint128 limit;
        uint128 spent;
        uint48 validAfter;
        uint48 validUntil;
    }

    address public immutable entryPoint;
    address public immutable owner;
    mapping(address => Session) public sessions;

    error NotEntryPoint();
    error NotSelf();
    error CallFailed(uint256 index, bytes reason);

    event SessionAdded(address indexed key, address target, bytes4 selector, uint128 limit, uint48 validUntil);
    event SessionRevoked(address indexed key);

    constructor(address entryPoint_, address owner_) {
        entryPoint = entryPoint_;
        owner = owner_;
    }

    receive() external payable {}

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        _;
    }

    // 持ち主が署名したUserOperationがexecute(このアカウント, 0, addSession(...))で呼ぶ
    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    function addSession(address key, Session calldata s) external onlySelf {
        sessions[key] = s;
        sessions[key].spent = 0;
        emit SessionAdded(key, s.target, s.selector, s.limit, s.validUntil);
    }

    function revokeSession(address key) external onlySelf {
        delete sessions[key];
        emit SessionRevoked(key);
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        address signer = _recover(userOpHash, userOp.signature);
        if (signer != address(0) && signer == owner) {
            validationData = 0;
        } else {
            validationData = _checkSession(signer, userOp);
        }
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            ok;
        }
    }

    // セッションキー: calldataを直接ほどいて範囲と照らし合わせる。合えば使った量を上げて期限を返す
    function _checkSession(address key, PackedUserOperation calldata op) internal returns (uint256) {
        Session storage s = sessions[key];
        if (key == address(0) || s.target == address(0)) return ValidationData.SIG_VALIDATION_FAILED;
        if (uint192(op.nonce >> 64) != uint192(uint160(key))) return ValidationData.SIG_VALIDATION_FAILED;
        if (op.callData.length < 4 || bytes4(op.callData[0:4]) != this.execute.selector) {
            return ValidationData.SIG_VALIDATION_FAILED;
        }
        (address target, uint256 value, bytes memory data) = abi.decode(op.callData[4:], (address, uint256, bytes));
        if (target != s.target || value != 0 || data.length != 68 || bytes4(data) != s.selector) {
            return ValidationData.SIG_VALIDATION_FAILED;
        }
        address asset;
        uint256 amount;
        assembly {
            asset := mload(add(data, 36))
            amount := mload(add(data, 68))
        }
        if (asset != s.asset || s.spent + amount > s.limit) return ValidationData.SIG_VALIDATION_FAILED;
        s.spent += uint128(amount);
        return ValidationData.pack(false, s.validUntil, s.validAfter);
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyEntryPoint {
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) revert CallFailed(0, ret);
    }

    function executeBatch(address[] calldata targets, bytes[] calldata datas) external onlyEntryPoint {
        for (uint256 i = 0; i < targets.length; i++) {
            (bool ok, bytes memory ret) = targets[i].call(datas[i]);
            if (!ok) revert CallFailed(i, ret);
        }
    }

    function _recover(bytes32 digest, bytes calldata sig) internal pure returns (address) {
        if (sig.length != 65) return address(0);
        return ecrecover(digest, uint8(sig[64]), bytes32(sig[0:32]), bytes32(sig[32:64]));
    }
}
