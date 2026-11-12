// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLock {
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public unlockAt;

    error TooEarly(uint256 nowTime, uint256 unlockTime);

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        unlockAt[msg.sender] = block.timestamp + 1 days;
    }

    function withdraw() external {
        if (block.timestamp <= unlockAt[msg.sender]) {
            revert TooEarly(block.timestamp, unlockAt[msg.sender]);
        }
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
