// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// 講義用のプリコンパイルの計測: ペアリング(0x08)とblobの一点の開示(0x0A)
contract Probe232 {
    /// ペアリングの確認。入力は(G1点、G2点)のペアごとに192バイト
    function pairing(bytes calldata input) external view returns (bool ok, uint256 result, uint256 gasUsed) {
        uint256 g = gasleft();
        bytes memory ret;
        (ok, ret) = address(0x08).staticcall(input);
        gasUsed = g - gasleft();
        if (ok && ret.length == 32) result = abi.decode(ret, (uint256));
    }

    /// blobの一点の開示の確認。入力 = versioned hash、z、y、コミットメント48バイト、証明48バイト
    function pointEval(bytes calldata input) external view returns (bool ok, bytes memory ret, uint256 gasUsed) {
        uint256 g = gasleft();
        (ok, ret) = address(0x0A).staticcall(input);
        gasUsed = g - gasleft();
    }
}
