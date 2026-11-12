// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Receiver {
    event Got(address sender, uint256 value);

    receive() external payable {
        emit Got(msg.sender, msg.value);
    }
}

contract Sender {
    function viaTransfer(address payable to) external payable {
        to.transfer(msg.value);
    }

    function viaSend(address payable to) external payable {
        bool ok = to.send(msg.value);
        require(ok, "send failed");
    }

    function viaCall(address payable to) external payable {
        (bool ok, ) = to.call{value: msg.value}("");
        require(ok, "call failed");
    }
}
