// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

error ShortInput(uint256 len);

// 第69講のスライスの前に長さの確認
contract Args {
    function firstArgRaw(bytes calldata data) external pure returns (uint256) {
        return uint256(bytes32(data[4:36]));
    }

    function firstArg(bytes calldata data) external pure returns (uint256) {
        require(data.length >= 36, ShortInput(data.length));
        return uint256(bytes32(data[4:36]));
    }
}

contract Refuser {
    receive() external payable {
        revert("no");
    }
}

// 失敗が値として返ってくる四つの場所
contract Checks {
    constructor() payable {}

    function lowCall(address to) external {
        (bool ok, ) = to.call{value: 1}("");
        require(ok, "call failed");
    }

    function sendIt(address payable to) external {
        bool sent = to.send(1);
        require(sent, "send failed");
    }

    function hashOf(uint256 n) external view returns (bytes32 h) {
        h = blockhash(n);
        require(h != bytes32(0), "no blockhash");
    }

    function signerOf(bytes32 digest, uint8 v, bytes32 r, bytes32 s) external pure returns (address signer) {
        signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "bad signature");
    }
}
