// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract FnTypes {
    function (uint256) internal pure returns (uint256) inner;
    function (uint256) external returns (bool) public outer;

    function double(uint256 x) public pure returns (uint256) {
        return x * 2;
    }

    function triple(uint256 x) internal pure returns (uint256) {
        return x * 3;
    }

    function useInternal(uint256 x) public pure returns (uint256) {
        function (uint256) internal pure returns (uint256) f = double;
        uint256 a = f(x);
        f = triple;
        return a + f(x);
    }

    function useExternal(uint256 x) public view returns (uint256) {
        function (uint256) external pure returns (uint256) g = this.double;
        return g(x);
    }

    function parts() public view returns (address, bytes4) {
        function (uint256) external pure returns (uint256) g = this.double;
        return (g.address, g.selector);
    }

    function callEmptyInner(uint256 x) public view returns (uint256) {
        return inner(x);
    }

    function callEmptyOuter(uint256 x) public returns (bool) {
        return outer(x);
    }
}
