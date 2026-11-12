// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Checked186 {
    enum Kind { A, B }
    uint256[] public list;

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    function subWrap(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }

    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function mulWrap(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a * b;
        }
    }

    // unchecked内で呼んだ関数の演算はチェックそのまま
    function subViaCall(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return _sub(a, b);
        }
    }

    function _sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    // unchecked内でも0除算は巻き戻す
    function divWrap(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked {
            return a / b;
        }
    }

    // 明示的な変換はチェックなし
    function narrow(uint256 a) external pure returns (uint64) {
        return uint64(a);
    }

    // 0.8.0: べき乗は右から結合
    function powChain() external pure returns (uint256) {
        uint256 a = 2;
        uint256 b = 3;
        uint256 c = 2;
        return a ** b ** c;
    }

    function negMin(int8 x) external pure returns (int8) {
        return -x;
    }

    function failAssert() external pure {
        assert(false);
    }

    function toKind(uint256 x) external pure returns (Kind) {
        return Kind(x);
    }

    function popEmpty() external {
        list.pop();
    }

    function at(uint256 i) external view returns (uint256) {
        return list[i];
    }
}
