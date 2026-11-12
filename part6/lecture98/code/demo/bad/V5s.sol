// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V5s {
    function f(address a) external view returns (bool ok) { (ok, ) = a.staticcall(""); }
}
