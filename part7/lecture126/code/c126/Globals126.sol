// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Globals126 {
    function blockRow() external view returns (uint256 number, uint256 timestamp, uint256 prevrandao, uint256 basefee, uint256 chainid, address coinbase, uint256 gaslimit) {
        return (block.number, block.timestamp, block.prevrandao, block.basefee, block.chainid, block.coinbase, block.gaslimit);
    }
    function callRow(uint256 x) external payable returns (address sender, bytes4 sig, uint256 value, address origin, uint256 gasprice, uint256 gasLeft, bytes memory data) {
        x;
        return (msg.sender, msg.sig, msg.value, tx.origin, tx.gasprice, gasleft(), msg.data);
    }
}
