// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Args {
    function extCd(uint256[] calldata a) external pure returns (uint256) { return a.length; }
    function pubCd(uint256[] calldata a) public pure returns (uint256) { return a.length; }
    function pubMem(uint256[] memory a) public pure returns (uint256) { return a.length; }
}
