// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第106講のデモ: 同じ名前、違う引数の型
contract Over {
    event Set(uint256 v);
    event Set(address v);

    function a() external { emit Set(uint256(1)); }
    function b() external { emit Set(address(1)); }
}

// 第106講のデモ: indexedの配置だけが違う二つの版
contract Plain {
    event Moved(address from, address to, uint256 amount);

    function move(address to, uint256 amount) external {
        emit Moved(msg.sender, to, amount);
    }
}

contract Indexed {
    event Moved(address indexed from, address indexed to, uint256 amount);

    function move(address to, uint256 amount) external {
        emit Moved(msg.sender, to, amount);
    }
}

// 第106講のデモ: 文字列をindexedに
contract Label {
    event Labeled(string indexed key, string text);

    function label(string calldata s) external {
        emit Labeled(s, s);
    }
}
