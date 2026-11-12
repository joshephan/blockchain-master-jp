// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 署名者の欄をまだ決めていない版
contract Gate {
    address public admin = msg.sender;
    address public signer;

    function setSigner(address s) external {
        require(msg.sender == admin, "not admin");
        signer = s;
    }

    function check(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns (bool) {
        return ecrecover(hash, v, r, s) == signer;
    }
}

// 復元結果を先に弾く版
contract SafeGate {
    address public admin = msg.sender;
    address public signer;

    function setSigner(address s) external {
        require(msg.sender == admin, "not admin");
        signer = s;
    }

    function check(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns (bool) {
        address got = ecrecover(hash, v, r, s);
        require(got != address(0), "bad signature");
        return got == signer;
    }
}
