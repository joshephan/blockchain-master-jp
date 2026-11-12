// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/// @notice 投票が一回終わると記録
event Voted(address indexed voter, uint256 proposal);

error NotChairperson(address caller);
