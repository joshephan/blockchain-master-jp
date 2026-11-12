// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 受取人の一覧に一度に分けて送る版
contract PushSplit {
    address[] public payees;

    function join() external {
        payees.push(msg.sender);
    }

    function joinMany(address[] calldata list) external {
        for (uint256 i = 0; i < list.length; i++) {
            payees.push(list[i]);
        }
    }

    function payAll() external payable {
        uint256 share = msg.value / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            (bool ok,) = payable(payees[i]).call{value: share}("");
            require(ok);
        }
    }
}

// 同じ一覧に取り分だけを記録しておき、各自が引き出しに来る版
contract PullSplit {
    address[] public payees;
    mapping(address => uint256) public owed;

    function join() external {
        payees.push(msg.sender);
    }

    function joinMany(address[] calldata list) external {
        for (uint256 i = 0; i < list.length; i++) {
            payees.push(list[i]);
        }
    }

    function payAll() external payable {
        uint256 share = msg.value / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            owed[payees[i]] += share;
        }
    }

    function withdraw() external {
        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok);
    }
}
