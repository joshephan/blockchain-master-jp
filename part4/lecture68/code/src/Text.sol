// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Pack {
    function makeBytes() external pure returns (uint256) {
        bytes memory b = new bytes(4);
        b[0] = 0x01;
        b[1] = 0x02;
        b[2] = 0x03;
        b[3] = 0x04;
        return b.length;
    }

    function makeArray() external pure returns (uint256) {
        bytes1[] memory a = new bytes1[](4);
        a[0] = 0x01;
        a[1] = 0x02;
        a[2] = 0x03;
        a[3] = 0x04;
        return a.length;
    }
}

contract ShortName {
    string public name = "abc";
}

contract LongName {
    string public name = "Lending Pool for Wrapped Ether";
    string public longer = "Lending Pool for Wrapped Ether and USD Coin";
}

contract Tags {
    bytes public tags;

    function add(bytes1 t) external {
        tags.push(t);
    }

    function first() external view returns (bytes1) {
        return tags[0];
    }

    function count() external view returns (uint256) {
        return tags.length;
    }
}

contract Market {
    bytes32 public marketId;
    string public marketName;

    constructor(string memory name) {
        marketId = keccak256(bytes(name));
        marketName = name;
    }
}

contract PackN {
    function makeBytes(uint256 n) external pure returns (uint256) {
        bytes memory b = new bytes(n);
        for (uint256 i = 0; i < n; i++) {
            b[i] = 0x01;
        }
        return b.length;
    }

    function makeArray(uint256 n) external pure returns (uint256) {
        bytes1[] memory a = new bytes1[](n);
        for (uint256 i = 0; i < n; i++) {
            a[i] = 0x01;
        }
        return a.length;
    }
}
