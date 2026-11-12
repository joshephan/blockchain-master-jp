// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Voucher {
    address public signer;

    constructor(address s) {
        signer = s;
    }

    // チェーン番号を入れていない版
    function digestNoChain(uint256 amount, uint256 nonce) public view returns (bytes32) {
        return keccak256(abi.encode(amount, nonce, address(this)));
    }

    // チェーン番号を入れた版
    function digestWithChain(uint256 amount, uint256 nonce) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, amount, nonce, address(this)));
    }

    function checkNoChain(uint256 amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s)
        external view returns (bool)
    {
        address got = ecrecover(digestNoChain(amount, nonce), v, r, s);
        return got != address(0) && got == signer;
    }

    function checkWithChain(uint256 amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s)
        external view returns (bool)
    {
        address got = ecrecover(digestWithChain(amount, nonce), v, r, s);
        return got != address(0) && got == signer;
    }
}
