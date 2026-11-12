// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ECDSA} from "../vendor/oz/utils/cryptography/ECDSA.sol";
import {EIP712} from "../vendor/oz/utils/cryptography/EIP712.sol";

// 講義用の最小のマルチシグ。署名はチェーンの外で集め、実行は一つのトランザクション。監査を受けたマルチシグの代わりには使わない
// 署名するハッシュにチェーン番号とこのウォレットのアドレス(EIP-712ドメイン)、何番目の取引か(nonce)が入る
// 対象はCALLでだけ呼ぶ(DELEGATECALLなし)、ガスの肩代わり・モジュール・ガードなし
contract MiniSafe is EIP712 {
    bytes32 public constant TX_TYPEHASH = keccak256("Tx(address to,uint256 value,bytes data,uint256 nonce)");

    mapping(address => bool) public isOwner;
    uint256 public ownerCount;
    uint256 public threshold;
    uint256 public nonce;

    error BadThreshold(uint256 threshold, uint256 owners);
    error BadOwner(address owner);
    error NotOwner(address signer);
    error NotSorted(address previous, address signer);
    error BelowThreshold(uint256 signatures, uint256 threshold);
    error CallFailed(bytes reason);
    error NotSelf(address caller);

    event Executed(uint256 indexed nonce, address indexed to, bytes32 txHash);
    event ThresholdChanged(uint256 threshold);

    constructor(address[] memory owners, uint256 t) EIP712("MiniSafe", "1") {
        for (uint256 i = 0; i < owners.length; i++) {
            address o = owners[i];
            if (o == address(0) || isOwner[o]) revert BadOwner(o);
            isOwner[o] = true;
        }
        ownerCount = owners.length;
        if (t == 0 || t > owners.length) revert BadThreshold(t, owners.length);
        threshold = t;
    }

    // 署名者が署名する32バイト
    function txHash(address to, uint256 value, bytes calldata data, uint256 n) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(TX_TYPEHASH, to, value, keccak256(data), n)));
    }

    // 署名は署名者アドレスの小さい順。同じ署名者が二回あると順番の検査で引っかかる
    function execute(address to, uint256 value, bytes calldata data, bytes[] calldata sigs)
        external
        returns (bytes memory)
    {
        if (sigs.length < threshold) revert BelowThreshold(sigs.length, threshold);
        bytes32 h = txHash(to, value, data, nonce);
        address last;
        for (uint256 i = 0; i < sigs.length; i++) {
            address s = ECDSA.recover(h, sigs[i]);
            if (!isOwner[s]) revert NotOwner(s);
            if (s <= last) revert NotSorted(last, s);
            last = s;
        }
        emit Executed(nonce, to, h);
        nonce++;
        (bool ok, bytes memory ret) = to.call{value: value}(data);
        if (!ok) revert CallFailed(ret);
        return ret;
    }

    // しきい値の変更はこのウォレット自身だけ(署名を集めてexecuteで自分を呼ぶ)
    function changeThreshold(uint256 t) external {
        if (msg.sender != address(this)) revert NotSelf(msg.sender);
        if (t == 0 || t > ownerCount) revert BadThreshold(t, ownerCount);
        threshold = t;
        emit ThresholdChanged(t);
    }

    receive() external payable {}
}
