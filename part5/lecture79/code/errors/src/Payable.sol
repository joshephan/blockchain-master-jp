// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Payable { function f(bytes32 h, uint8 v, bytes32 r, bytes32 s) external { payable(ecrecover(h, v, r, s)).transfer(1); address payable p = ecrecover(h, v, r, s); } }
