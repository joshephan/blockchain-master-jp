// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第105講のデモ: 宣言と発行
contract Note {
    event Noted(address who, uint256 n);

    function note(uint256 n) external {
        emit Noted(msg.sender, n);
    }

    function noteNamed(uint256 n) external {
        emit Noted({n: n, who: msg.sender});
    }

    function topic0() external pure returns (bytes32) {
        return Noted.selector;
    }
}

// 第105講のデモ: 同じ値をストレージに積む版
contract History {
    uint256[] public ns;

    function keep(uint256 n) external {
        ns.push(n);
    }
}

// 第105講のデモ: 出力してから巻き戻る
contract Fail {
    event Tried(uint256 n);
    uint256 public tries;

    function tryIt(uint256 n) external {
        tries += 1;
        emit Tried(n);
        revert("no");
    }
}

// 第105講のデモ: 内側の呼び出しだけが巻き戻る
contract Inner {
    event InnerLog(uint256 n);

    function run(uint256 n) external {
        emit InnerLog(n);
        revert("inner failed");
    }
}

contract Outer {
    event Before(uint256 n);
    event After(bool ok);
    Inner public inner = new Inner();

    function go(uint256 n) external {
        emit Before(n);
        try inner.run(n) {
            emit After(true);
        } catch {
            emit After(false);
        }
    }
}

// 第105講のデモ: 同じ名前、違う引数の型
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

// 第107講のデモ: 匿名イベント
contract Anon {
    event Moved(address indexed from, address indexed to, uint256 amount) anonymous;
    event Four(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 indexed d) anonymous;

    function move(address to, uint256 amount) external {
        emit Moved(msg.sender, to, amount);
    }

    function four() external {
        emit Four(1, 2, 3, 4);
    }
}

// 第107講のデモ: Marketと同じ形のログを出す任意のコントラクト
contract Fake {
    event Deposited(address indexed asset, address indexed user, uint256 amount);

    function fake(address asset, address user, uint256 amount) external {
        emit Deposited(asset, user, amount);
    }
}
