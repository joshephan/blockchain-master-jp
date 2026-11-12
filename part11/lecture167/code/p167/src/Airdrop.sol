// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/// @notice 番号ごとに受け取る分が決まった配布。番号四つ、一つ100ずつ、全体400
contract Airdrop {
    error NotOwner(uint256 id);
    error AlreadyClaimed(uint256 id);

    mapping(uint256 id => address) public ownerOf;
    mapping(uint256 id => bool) public claimed;
    mapping(address user => uint256) public paid;
    uint256 public remaining = 400;
    uint256 public constant SHARE = 100;

    constructor(address a, address b) {
        ownerOf[0] = a;
        ownerOf[1] = a;
        ownerOf[2] = b;
        ownerOf[3] = b;
    }

    /// @notice 自分の番号複数を一度に受け取る
    function claim(uint256[] calldata ids) external {
        // まずすべてを確認
        for (uint256 i = 0; i < ids.length; i++) {
            if (ownerOf[ids[i]] != msg.sender) revert NotOwner(ids[i]);
            if (claimed[ids[i]]) revert AlreadyClaimed(ids[i]);
        }
        // その後すべてに印を付けて支払う
        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            claimed[ids[i]] = true;
            total += SHARE;
        }
        remaining -= total;
        paid[msg.sender] += total;
    }
}
