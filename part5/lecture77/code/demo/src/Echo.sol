// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Echo {
    function echo(uint256, address)
        external
        payable
        returns (bytes memory data, bytes4 sig, address sender, uint256 value)
    {
        return (msg.data, msg.sig, msg.sender, msg.value);
    }

    function args(uint256, address) external pure returns (bytes memory) {
        return msg.data[4:];
    }

    function pureSig() external pure returns (bytes4) {
        return msg.sig;
    }

    function viewSender() external view returns (address) {
        return msg.sender;
    }
}
