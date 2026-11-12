// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

error InsufficientDeposit(uint256 have, uint256 want);

// 失敗の仕方ごとに関数一つ
contract Target {
    uint256 public count;

    event Touched(uint256 count);

    function ok() external returns (bool) {
        count += 1;
        emit Touched(count);
        return true;
    }

    function failRequire() external {
        count += 1;
        emit Touched(count);
        require(count > 100, "too small");
    }

    function failAssert() external {
        count += 1;
        emit Touched(count);
        assert(count > 100);
    }

    function failOverflow() external {
        count += 1;
        emit Touched(count);
        uint8 x = uint8(count) + 255;
        count = x;
    }

    function failCustom() external {
        count += 1;
        emit Touched(count);
        revert InsufficientDeposit(10, 30);
    }

    function failEmpty() external {
        count += 1;
        emit Touched(count);
        revert();
    }

    // Error(string)セレクターの4バイトだけを返して巻き戻す
    function failBadError() external pure {
        assembly {
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            revert(0, 4)
        }
    }

    // ガスを使い切るまで回る
    function burn() external {
        count += 1;
        while (true) {}
    }
}
