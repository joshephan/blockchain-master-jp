// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// バッチの記録箱: blobで上げたバッチ、委員会が署名したバッチ、ハッシュだけを上げたバッチ
contract Inbox231 {
    enum Kind {
        Blob,
        Attested,
        HashOnly
    }

    struct Batch {
        bytes32 dataHash;
        Kind kind;
        uint64 blockNo;
    }

    Batch[] public batches;
    address public immutable committee;

    error NoBlob();
    error NotCommittee(address signer);

    constructor(address committee_) {
        committee = committee_;
    }

    /// このトランザクションに載った最初のblobのハッシュを記録する
    function postBlob() external {
        bytes32 h = blobhash(0);
        if (h == bytes32(0)) revert NoBlob();
        batches.push(Batch(h, Kind.Blob, uint64(block.number)));
    }

    /// 委員会の鍵が署名したハッシュを記録する(データを受け取ったという署名だけ確認)
    function postAttested(bytes32 h, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", h));
        address signer = ecrecover(digest, v, r, s);
        if (signer != committee) revert NotCommittee(signer);
        batches.push(Batch(h, Kind.Attested, uint64(block.number)));
    }

    /// 受け取ったハッシュをそのまま記録する(データがどこにあるかは確認しない)
    function postHash(bytes32 h) external {
        batches.push(Batch(h, Kind.HashOnly, uint64(block.number)));
    }

    function count() external view returns (uint256) {
        return batches.length;
    }
}
