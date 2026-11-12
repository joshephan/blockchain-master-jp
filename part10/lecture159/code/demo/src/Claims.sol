// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 何を聞かれてもtrue(デモ用)
contract Liar {
    function supportsInterface(bytes4) external pure returns (bool) {
        return true;
    }
}

// ERC-165の手順は通るように答え、ERC-721だと言うが、ERC-721の関数は一つもない(デモ用)
contract SelectiveLiar {
    function supportsInterface(bytes4 id) external pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }
}

// supportsInterfaceの中でガスを大量に使う(デモ用)
contract GasHog {
    function supportsInterface(bytes4 id) external view returns (bool) {
        uint256 x;
        for (uint256 i = 0; i < 2000; i++) {
            x ^= uint256(keccak256(abi.encode(i, block.number)));
        }
        return id == 0x01ffc9a7 || x == 0;
    }
}
