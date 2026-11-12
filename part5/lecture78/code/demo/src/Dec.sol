// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Dec {
    function pair(bytes calldata data) external pure returns (uint256 n, address a) {
        (n, a) = abi.decode(data, (uint256, address));
    }

    function pairSwapped(bytes calldata data) external pure returns (address a, uint256 n) {
        (a, n) = abi.decode(data, (address, uint256));
    }

    function take(address to, uint256 amount) external pure returns (address a, uint256 n) {
        to; amount;
        (a, n) = abi.decode(msg.data[4:], (address, uint256));
    }

    function asUint(bytes calldata data) external pure returns (uint256) {
        return abi.decode(data, (uint256));
    }

    function asBytes32(bytes calldata data) external pure returns (bytes32) {
        return abi.decode(data, (bytes32));
    }

    function asAddress(bytes calldata data) external pure returns (address) {
        return abi.decode(data, (address));
    }

    function asBool(bytes calldata data) external pure returns (bool) {
        return abi.decode(data, (bool));
    }

    function asBytes(bytes calldata data) external pure returns (bytes memory) {
        return abi.decode(data, (bytes));
    }

    function asString(bytes calldata data) external pure returns (string memory) {
        return abi.decode(data, (string));
    }
}
