// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BlockInfo {
    function header()
        external
        view
        returns (
            uint256 number,
            uint256 timestamp,
            uint256 basefee,
            uint256 gaslimit,
            address coinbase,
            uint256 prevrandao
        )
    {
        return (
            block.number,
            block.timestamp,
            block.basefee,
            block.gaslimit,
            block.coinbase,
            block.prevrandao
        );
    }

    function chain() external view returns (uint256) {
        return block.chainid;
    }

    function hashOf(uint256 n) external view returns (bytes32) {
        return blockhash(n);
    }

    function checkedHash(uint256 n) external view returns (bytes32) {
        bytes32 h = blockhash(n);
        require(h != bytes32(0), "no hash");
        return h;
    }

    function hashes() external view returns (bytes32 current, bytes32 prev, bytes32 old) {
        current = blockhash(block.number);
        prev = blockhash(block.number - 1);
        old = blockhash(block.number - 257);
    }

    function gasLeft() external view returns (uint256) {
        return gasleft();
    }
}

contract TxRecorder {
    uint256 public gasPrice;
    address public origin;
    uint256 public basefee;

    function record() external {
        gasPrice = tx.gasprice;
        origin = tx.origin;
        basefee = block.basefee;
    }
}
