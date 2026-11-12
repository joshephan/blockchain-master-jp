// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract AllPublic { uint256 public a; uint256 public b; uint256 public c; }
contract AllInternal { uint256 a; uint256 b; uint256 c; }
contract OnePublic { uint256 public a; uint256 b; uint256 c; }
