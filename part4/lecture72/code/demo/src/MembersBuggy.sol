// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MembersBuggy {
    mapping(address => uint256) public balanceOf; // 値のマッピング
    address[] public keys;                        // キーの一覧
    mapping(address => uint256) public indexOf;   // 一覧の位置 + 1、0なら一覧にない

    function deposit(uint256 amount) external {
        _put(msg.sender, amount);
    }

    function _put(address k, uint256 amount) internal {
        if (indexOf[k] == 0) {
            keys.push(k);
            indexOf[k] = keys.length;
        }
        balanceOf[k] += amount;
    }

    function exit() external {
        address k = msg.sender;
        uint256 pos = indexOf[k];
        require(pos != 0, "not listed");
        uint256 last = keys.length;
        if (pos != last) {
            address moved = keys[last - 1];
            keys[pos - 1] = moved;
        }
        keys.pop();
        delete indexOf[k];
        delete balanceOf[k];
    }

    function count() external view returns (uint256) {
        return keys.length;
    }

    function listAll() external view returns (address[] memory) {
        return keys;
    }

    function sumAll() external view returns (uint256 s) {
        for (uint256 i = 0; i < keys.length; i++) {
            s += balanceOf[keys[i]];
        }
    }
}

