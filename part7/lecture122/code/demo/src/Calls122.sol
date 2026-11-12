// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第122講のデモ: 呼ぶ側(Raw)と呼ばれる側(Echo)
interface IEcho {
    function value() external view returns (uint256);
}

contract Echo {
    error Nope(uint256 code);
    uint256 public stored; // スロット0

    function value() external pure returns (uint256) { return 42; }
    function two() external pure returns (uint256, uint256) { return (1, 2); }
    function fail() external pure { revert Nope(7); }
    function store(uint256 v) external { stored = v; }
}

contract Boom {
    constructor() { revert("no"); }
}

contract Raw {
    uint256 public stored; // スロット0。Echo.storeをdelegatecallで呼ぶとこの欄が変わる

    // 文法で呼ぶ
    function viaSolidity(address t) external view returns (uint256) {
        return IEcho(t).value();
    }

    // 手で呼ぶ: staticcall(ガス, アドレス, 入力の位置, 入力の長さ, 出力の位置, 出力の長さ)
    function viaAssembly(address t) external view returns (uint256 ok, uint256 v) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x3fa4f245)) // value()
            ok := staticcall(gas(), t, p, 4, p, 0x20)
            v := mload(p)
        }
    }

    // 出力の欄を32バイトと決めておき、64バイトの答えを受け取る
    function cut(address t) external view returns (uint256 first, uint256 second, uint256 size) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x5fdf05d7)) // two()
            mstore(add(p, 0x20), 0)
            pop(staticcall(gas(), t, p, 4, p, 0x20))
            first := mload(p)
            second := mload(add(p, 0x20))
            size := returndatasize()
        }
    }

    // 来た分を全部受け取る
    function whole(address t) external view returns (uint256 first, uint256 second, uint256 size) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x5fdf05d7))
            pop(staticcall(gas(), t, p, 4, 0, 0))
            size := returndatasize()
            returndatacopy(p, 0, size)
            first := mload(p)
            second := mload(add(p, 0x20))
        }
    }

    // あるより多く取ってこようとすると、この呼び出し全体が巻き戻る
    function overCopy(address t) external view returns (uint256 x) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x3fa4f245))
            pop(staticcall(gas(), t, p, 4, 0, 0))
            returndatacopy(p, 0, 0x40)
            x := mload(p)
        }
    }

    // 失敗しても巻き戻らない。0が返ってきて次の行が実行される
    function failQuiet(address t) external returns (uint256 ok, uint256 size, bytes32 head, uint256 after_) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0xa9cc4718)) // fail()
            ok := call(gas(), t, 0, p, 4, 0, 0)
            size := returndatasize()
            returndatacopy(p, 0, size)
            head := mload(p)
            after_ := 1
        }
        stored = 99;
    }

    // 受け取った巻き戻りデータをそのまま上に送る
    function bubble(address t) external {
        (bool ok, bytes memory data) = t.call(abi.encodeWithSignature("fail()"));
        if (!ok) {
            assembly {
                revert(add(data, 0x20), mload(data))
            }
        }
    }

    // コードのないアドレス: 三つで呼ぶ
    function codeless(address t) external returns (uint256 asmOk, bool lowOk) {
        assembly {
            asmOk := call(gas(), t, 0, 0, 0, 0, 0)
        }
        (lowOk, ) = t.call(abi.encodeWithSignature("value()"));
    }

    function codelessSolidity(address t) external view returns (uint256) {
        return IEcho(t).value();
    }

    // 手でかけるdelegatecall: EchoのコードがRawのストレージで動く
    function delegateStore(address t, uint256 v) external returns (uint256 ok) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x6057361d)) // store(uint256)
            mstore(add(p, 4), v)
            ok := delegatecall(gas(), t, p, 0x24, 0, 0)
        }
    }

    // create2: 値、コードの位置、コード長、salt
    function deploy2(bytes32 salt) external returns (address a) {
        bytes memory code = type(Echo).creationCode;
        assembly {
            a := create2(0, add(code, 0x20), mload(code), salt)
        }
    }

    // 作られたかを確認する行を付けた版
    function deploy2Checked(bytes32 salt) external returns (address a) {
        bytes memory code = type(Echo).creationCode;
        assembly {
            a := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(a) { revert(0, 0) }
        }
    }

    // コンストラクタが巻き戻ると0が返る
    function deployBoom() external returns (address a) {
        bytes memory code = type(Boom).creationCode;
        assembly {
            a := create(0, add(code, 0x20), mload(code))
        }
    }

    function deployBoomSolidity() external returns (address) {
        return address(new Boom());
    }
}

// ディスパッチャーを手で: 先頭4バイトを読んで分岐を選ぶ
contract Mini {
    fallback() external {
        assembly {
            let sel := shr(224, calldataload(0))
            switch sel
            case 0x3fa4f245 { // value()
                mstore(0, 42)
                return(0, 0x20)
            }
            case 0x5fdf05d7 { // two()
                mstore(0, 1)
                mstore(0x20, 2)
                return(0, 0x40)
            }
            default { revert(0, 0) }
        }
    }
}
