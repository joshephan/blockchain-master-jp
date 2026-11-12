// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IPair249 {
    function a() external view returns (uint256);
    function b() external view returns (uint256);
}

// 呼ばれる側: 呼んだコントラクトの二つの欄を読んで書いておく。failは常にリバート
contract Observer249 {
    error Nope();

    uint256 public seenA;
    uint256 public seenB;

    function ping(address src) external {
        seenA = IPair249(src).a();
        seenB = IPair249(src).b();
    }

    function fail() external pure {
        revert Nope();
    }
}
