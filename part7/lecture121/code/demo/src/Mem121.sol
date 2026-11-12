// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第121講のデモ: メモリの先頭四つの欄と0x40の欄
contract Mem121 {
    uint256 public first;                   // スロット0
    mapping(address => uint256) public bal; // スロット1

    // 関数が始まるときの先頭四つの欄
    function firstWords() public pure returns (uint256 w0, uint256 w1, uint256 w2, uint256 w3) {
        assembly {
            w0 := mload(0x00)
            w1 := mload(0x20)
            w2 := mload(0x40)
            w3 := mload(0x60)
        }
    }

    // マッピングを読んだ後の先頭二つの欄: コンパイラがハッシュの材料を置いた場所
    function afterMapping(address who) public view returns (uint256 v, uint256 w0, uint256 w1) {
        v = bal[who];
        assembly {
            w0 := mload(0x00)
            w1 := mload(0x20)
        }
    }

    // 0x40を動かさずに書いた値: 次のSolidityの値が同じ場所に入る
    function noBump() public pure returns (uint256 mine, uint256 at, uint256 encodedAt) {
        assembly {
            at := mload(0x40)
            mstore(at, 0x1234)
        }
        bytes memory e = abi.encode(uint256(7));
        assembly {
            mine := mload(at)
            encodedAt := e
        }
    }

    // 0x40を動かして書いた値
    function withBump() public pure returns (uint256 mine, uint256 at, uint256 encodedAt) {
        assembly {
            at := mload(0x40)
            mstore(at, 0x1234)
            mstore(0x40, add(at, 0x20))
        }
        bytes memory e = abi.encode(uint256(7));
        assembly {
            mine := mload(at)
            encodedAt := e
        }
    }

    // 空の配列が指す0x60の欄
    function zeroSlot() public pure returns (uint256 p, uint256 len) {
        bytes memory empty;
        assembly {
            p := empty
            len := mload(empty)
        }
    }

    function dirtyZeroSlot() public pure returns (uint256 len) {
        assembly { mstore(0x60, 5) }
        bytes memory empty;
        len = empty.length;
    }

    // 短い型の値の上位ビット
    function dirty() public pure returns (uint8 r, uint256 raw, bool same) {
        uint8 x;
        assembly { x := 300 }
        r = x;
        assembly { raw := x }
        same = (x == 44);
    }
}
