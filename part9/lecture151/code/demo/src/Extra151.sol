// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 受け取ったcalldataをそのまま渡すコントラクト
contract Relay {
    function forward(address target, bytes calldata data) external payable returns (bytes memory) {
        (bool ok, bytes memory ret) = target.call{value: msg.value}(data);
        if (!ok) {
            assembly {
                revert(add(ret, 32), mload(ret))
            }
        }
        return ret;
    }
}

// ドキュメントのonlyByをtx.originに変えた版
contract OriginGate {
    address public owner = msg.sender;

    error Unauthorized();

    modifier onlyByOrigin(address account) {
        if (tx.origin != account) revert Unauthorized();
        _;
    }

    function changeOwner(address newOwner) public onlyByOrigin(owner) {
        owner = newOwner;
    }
}

// ドキュメントのcosts modifierそのまま、本文ですぐreturnする関数
contract CostsReturn {
    address public owner;

    error NotEnoughEther();

    modifier costs(uint256 amount) {
        if (msg.value < amount) revert NotEnoughEther();

        _;
        if (msg.value > amount) {
            (bool success,) = payable(msg.sender).call{value: msg.value - amount}("");
            require(success);
        }
    }

    function payAndReturn(address newOwner) public payable costs(1 ether) {
        owner = newOwner;
        return;
    }
}

// 受け取るときに巻き戻すコントラクト
contract NoRefund {
    function buy(address target, address newOwner) external payable {
        (bool ok,) = target.call{value: msg.value}(abi.encodeWithSignature("forceOwnerChange(address)", newOwner));
        require(ok, "buy failed");
    }

    receive() external payable {
        revert("no refund");
    }
}
