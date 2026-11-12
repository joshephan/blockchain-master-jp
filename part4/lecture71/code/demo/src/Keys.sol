// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

contract Keys {
    enum Status { Active, Paused }

    mapping(uint256 => bool) public byUint;
    mapping(bytes32 => uint256) public byHash;
    mapping(bytes => uint256) public byBytes;
    mapping(string => uint256) public byName;
    mapping(IERC20 => uint256) public byToken;
    mapping(Status => uint256) public byStatus;
    mapping(Amount => uint256) public byAmount;
    mapping(address => mapping(address => uint256)) public nested;
    mapping(address => uint256[]) public lists;
}
