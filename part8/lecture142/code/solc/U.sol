// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {L} from "./L.sol";
contract U {
    function g(uint256 a) external pure returns (uint256) { return L.f(a); }
    function h(uint256 a) external pure returns (uint256) { require(a > 0, "zero"); return a; }
}
