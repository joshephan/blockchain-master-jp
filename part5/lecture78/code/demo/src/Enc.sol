// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Enc {
    address constant TO = 0x000000000000000000000000000000000000bEEF;

    function u8() external pure returns (bytes memory e, bytes memory p) {
        e = abi.encode(uint8(1));
        p = abi.encodePacked(uint8(1));
    }

    function str() external pure returns (bytes memory) {
        return abi.encode("abc");
    }

    function five(uint256 amount) external pure returns (
        bytes memory a, bytes memory b, bytes memory c, bytes memory d, bytes memory e
    ) {
        a = abi.encode(TO, amount);
        b = abi.encodePacked(TO, amount);
        c = abi.encodeWithSelector(IERC20.transfer.selector, TO, amount);
        d = abi.encodeWithSignature("transfer(address,uint256)", TO, amount);
        e = abi.encodeCall(IERC20.transfer, (TO, amount));
    }

    function typo(uint256 amount) external pure returns (bytes memory d1, bytes memory d2) {
        d1 = abi.encodeWithSignature("transfer(address,uint)", TO, amount);
        d2 = abi.encodeWithSignature("transfer(address, uint256)", TO, amount);
    }

    function wrongArg() external pure returns (bytes memory) {
        return abi.encodeWithSelector(IERC20.transfer.selector, TO, "1");
    }

    function packedSizes() external pure returns (bytes memory addr, bytes memory s, bytes memory arr) {
        uint8[] memory xs = new uint8[](2);
        xs[0] = 1;
        xs[1] = 2;
        addr = abi.encodePacked(TO);
        s = abi.encodePacked("abc");
        arr = abi.encodePacked(xs);
    }

    function collide() external pure returns (bytes memory p1, bytes memory p2, bytes memory e1, bytes memory e2) {
        p1 = abi.encodePacked("a", "bc");
        p2 = abi.encodePacked("ab", "c");
        e1 = abi.encode("a", "bc");
        e2 = abi.encode("ab", "c");
    }

    function fixedOnly(uint256 amount, uint256 nonce) external pure returns (bytes memory) {
        return abi.encodePacked(TO, amount, nonce);
    }
}
