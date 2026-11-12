// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IAccount, ValidationData} from "./UserOp.sol";

// 講義用の最小のERC-4337アカウント。持ち主の鍵一つでuserOpHashの署名を確認
contract Account219 is IAccount {
    address public immutable entryPoint;
    address public immutable owner;

    error NotEntryPoint();
    error CallFailed(uint256 index, bytes reason);

    constructor(address entryPoint_, address owner_) {
        entryPoint = entryPoint_;
        owner = owner_;
    }

    receive() external payable {}

    modifier onlyEntryPoint() {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        _;
    }

    // 署名が間違っていたらリバートせず1を返す(原文SIG_VALIDATION_FAILED)
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        address signer = _recover(userOpHash, userOp.signature);
        bool failed = signer == address(0) || signer != owner;
        validationData = ValidationData.pack(failed, 0, 0);
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            ok; // 足りなければEntryPointがAA21でリバート
        }
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
        bytes32 r = bytes32(sig[0:32]);
        bytes32 s = bytes32(sig[32:64]);
        uint8 v = uint8(sig[64]);
        return ecrecover(digest, v, r, s);
    }
}
