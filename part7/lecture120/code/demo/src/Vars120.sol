// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第120講のデモ: 外側の変数名がアセンブリブロックで何になるか
contract Vars120 {
    enum Stage { Open, Locked, Closed }

    uint8 public small;        // スロット0、オフセット0
    uint8 public small2;       // スロット0、オフセット1
    Stage public stage;        // スロット0、オフセット2
    uint256 public big;        // スロット1
    uint256[] public arr;      // スロット2
    mapping(address => uint256) public bal; // スロット3
    uint256 constant K = 7;

    function slots() public pure returns (uint256 s0, uint256 o0, uint256 s1, uint256 o1, uint256 s2, uint256 o2, uint256 sb, uint256 sa, uint256 sm) {
        assembly {
            s0 := small.slot
            o0 := small.offset
            s1 := small2.slot
            o1 := small2.offset
            s2 := stage.slot
            o2 := stage.offset
            sb := big.slot
            sa := arr.slot
            sm := bal.slot
        }
    }

    // 値型のローカル変数: 値そのまま
    function localValue(uint256 x) public pure returns (uint256 r) {
        assembly { r := x }
    }

    // memory変数: メモリアドレス
    function memoryRef() public pure returns (uint256 p, uint256 len, uint256 freeBefore) {
        assembly { freeBefore := mload(0x40) }
        bytes memory b = "hello";
        assembly {
            p := b
            len := mload(b)
        }
    }

    // calldata配列: .offsetと.length
    function calldataRef(bytes calldata d) public pure returns (uint256 o, uint256 l, bytes32 first) {
        assembly {
            o := d.offset
            l := d.length
            first := calldataload(d.offset)
        }
    }

    // storageローカル変数: .slot
    function storageRef() public view returns (uint256 s) {
        uint256[] storage a = arr;
        assembly { s := a.slot }
    }

    // constantは名前で値を使う
    function constantValue() public pure returns (uint256 r) {
        assembly { r := K }
    }

    // 外部関数の値: .addressと.selector
    function ping() external {}
    function fnParts() public view returns (address a, bytes4 s, uint256 raw) {
        function() external fp = this.ping;
        assembly {
            a := fp.address
            s := fp.selector
            raw := fp.selector
        }
    }

    // bytes4は左詰めなので224ビットずらして入れる
    function fnSelectorShifted() public view returns (bytes4 s) {
        function() external fp = this.ping;
        assembly { s := shl(224, fp.selector) }
    }

    // 0.8の文法で書く行: 範囲チェックが付く
    function setSmall(uint8 v) public { small = v; }
    function setStage(uint8 v) public { stage = Stage(v); }
    function setBig(uint256 v) public { big = v; }
    function push(uint256 v) public { arr.push(v); }

    // アセンブリで欄に丸ごと書く: 同じスロットの隣も上書きする
    function pokeSlot0(uint256 v) public {
        assembly { sstore(small.slot, v) }
    }

    // .offsetを使って1バイトだけ直す
    function pokeSmall(uint256 v) public {
        assembly {
            let word := sload(small.slot)
            let shift := mul(small.offset, 8)
            word := and(word, not(shl(shift, 0xff)))
            word := or(word, shl(shift, and(v, 0xff)))
            sstore(small.slot, word)
        }
    }

    function rawSlot(uint256 s) public view returns (bytes32 r) {
        assembly { r := sload(s) }
    }

    // ローカル変数に範囲外の値を入れる
    function smallLocal() public pure returns (uint8 r) {
        assembly { r := 300 }
    }

    function smallLocalWide() public pure returns (uint256 w) {
        uint8 r;
        assembly { r := 300 }
        w = r;
    }

    function smallLocalRaw() public pure returns (uint256 w) {
        uint8 r;
        assembly { r := 300 }
        assembly { w := r }
    }
}
