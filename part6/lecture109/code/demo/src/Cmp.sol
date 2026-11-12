// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 同じチェック、理由の書き方だけが違う版
contract ReqStr {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "not enough deposit");
        have -= want;
    }
}
contract ReqErr {
    error Short(uint256 have, uint256 want);
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, Short(have, want));
        have -= want;
    }
}
contract IfErr {
    error Short(uint256 have, uint256 want);
    uint256 public have = 3;
    function take(uint256 want) external {
        if (want > have) revert Short(have, want);
        have -= want;
    }
}
contract NoArg {
    error Short();
    uint256 public have = 3;
    function take(uint256 want) external {
        if (want > have) revert Short();
        have -= want;
    }
}
contract Bare {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have);
        have -= want;
    }
}

// 引数の計算タイミング
contract Eval {
    error Short(uint256 n);
    uint256 public calls;
    function count() internal returns (uint256) { calls += 1; return calls; }
    function withReq(uint256 x) external { require(x > 0, Short(count())); }
    function withIf(uint256 x) external { if (x == 0) revert Short(count()); }
    function withStr(uint256 x) external { require(x > 0, string(abi.encodePacked("n=", uint8(48 + count())))); }
}
contract Len5 {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "aaaaa");
        have -= want;
    }
}
contract Len31 {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        have -= want;
    }
}
contract Len32 {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        have -= want;
    }
}
contract Len33 {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        have -= want;
    }
}
contract Len64 {
    uint256 public have = 3;
    function take(uint256 want) external {
        require(want <= have, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        have -= want;
    }
}
