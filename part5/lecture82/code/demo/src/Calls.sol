// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Calls {
    function _who() internal view returns (address) {
        return msg.sender;
    }

    function who() public view returns (address) {
        return msg.sender;
    }

    function viaInternal() external view returns (address) {
        return _who();
    }

    function viaPublic() external view returns (address) {
        return who();
    }

    function viaThis() external view returns (address) {
        return this.who();
    }

    // memory配列を渡す二つの版
    function _bump(uint256[] memory a) internal pure {
        a[0] += 1;
    }

    function bump(uint256[] memory a) public pure {
        a[0] += 1;
    }

    function memInternal() external pure returns (uint256) {
        uint256[] memory a = new uint256[](1);
        a[0] = 1;
        _bump(a);
        return a[0];
    }

    function memThis() external view returns (uint256) {
        uint256[] memory a = new uint256[](1);
        a[0] = 1;
        this.bump(a);
        return a[0];
    }

    // 再帰: n回自分自身を呼ぶ
    function depth(uint256 n) public pure returns (uint256) {
        if (n == 0) {
            return 0;
        }
        return depth(n - 1) + 1;
    }
}
