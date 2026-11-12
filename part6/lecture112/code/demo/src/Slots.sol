// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第112講のデモ: 親が複数あるときのスロットの順番
contract SBase { uint256 public base = 1; }
contract SA is SBase { uint256 public a = 2; }
contract SB is SBase { uint256 public b = 3; }
contract SAB is SA, SB { uint256 public top = 4; }
contract SBA is SB, SA { uint256 public top = 4; }
