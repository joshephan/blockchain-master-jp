// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IAccount, ValidationData} from "./UserOp.sol";

// 講義用のソーシャルリカバリーアカウント。普段は持ち主の鍵一つ、鍵をなくしたら保護者のしきい値分の署名 + 待機のあと持ち主を交代
// 保護者はお金を動かせない。できることは持ち主の交代を始めること一つ
contract Recovery223 is IAccount {
    struct Pending {
        address newOwner;
        uint64 readyAt;
    }

    address public immutable entryPoint;
    uint256 public immutable threshold;
    uint256 public immutable delay;
    address public owner;
    mapping(address => bool) public isGuardian;
    uint256 public recoveryNonce;
    Pending public pending;

    error NotEntryPoint();
    error NotSelf();
    error NotGuardian(address signer);
    error GuardiansNotSorted();
    error NotEnoughGuardians(uint256 have, uint256 want);
    error RecoveryPending();
    error NoPendingRecovery();
    error RecoveryNotReady(uint64 readyAt);
    error CallFailed(uint256 index, bytes reason);

    event RecoveryStarted(address indexed newOwner, uint64 readyAt, uint256 recoveryNonce);
    event RecoveryCancelled(address indexed newOwner);
    event RecoveryFinished(address indexed oldOwner, address indexed newOwner);

    constructor(address entryPoint_, address owner_, address[] memory guardians_, uint256 threshold_, uint256 delay_) {
        entryPoint = entryPoint_;
        owner = owner_;
        for (uint256 i = 0; i < guardians_.length; i++) {
            isGuardian[guardians_[i]] = true;
        }
        threshold = threshold_;
        delay = delay_;
    }

    receive() external payable {}

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();
        _;
    }

    // 保護者が署名する値: チェーン番号、このアカウントのアドレス、復旧の使用番号、新しい持ち主
    function recoveryDigest(address newOwner) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), recoveryNonce, newOwner));
    }

    // 誰でも送れる。保護者の署名がしきい値以上、署名者アドレスの昇順(同じ保護者を二回数えられない)
    function startRecovery(address newOwner, bytes[] calldata sigs) external {
        if (pending.readyAt != 0) revert RecoveryPending();
        bytes32 digest = recoveryDigest(newOwner);
        address last;
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = _recover(digest, sigs[i]);
            if (!isGuardian[signer]) revert NotGuardian(signer);
            if (signer <= last) revert GuardiansNotSorted();
            last = signer;
        }
        if (sigs.length < threshold) revert NotEnoughGuardians(sigs.length, threshold);
        uint64 readyAt = uint64(block.timestamp + delay);
        pending = Pending(newOwner, readyAt);
        emit RecoveryStarted(newOwner, readyAt, recoveryNonce);
        recoveryNonce++;
    }

    // 待っているあいだに持ち主の鍵が署名したUserOperationで取り消す
    function cancelRecovery() external onlySelf {
        if (pending.readyAt == 0) revert NoPendingRecovery();
        emit RecoveryCancelled(pending.newOwner);
        delete pending;
    }

    // 待機が終われば誰でも送れる
    function finishRecovery() external {
        Pending memory p = pending;
        if (p.readyAt == 0) revert NoPendingRecovery();
        if (block.timestamp < p.readyAt) revert RecoveryNotReady(p.readyAt);
        emit RecoveryFinished(owner, p.newOwner);
        owner = p.newOwner;
        delete pending;
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        address signer = _recover(userOpHash, userOp.signature);
        validationData = ValidationData.pack(signer == address(0) || signer != owner, 0, 0);
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            ok;
        }
    }

    function execute(address target, uint256 value, bytes calldata data) external onlyEntryPoint {
        (bool ok, bytes memory ret) = target.call{value: value}(data);
        if (!ok) revert CallFailed(0, ret);
    }

    function _recover(bytes32 digest, bytes calldata sig) internal pure returns (address) {
        if (sig.length != 65) return address(0);
        return ecrecover(digest, uint8(sig[64]), bytes32(sig[0:32]), bytes32(sig[32:64]));
    }
}
