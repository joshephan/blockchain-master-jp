// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Ratio is uint8;
interface IERC20 { function transfer(address to, uint256 amount) external returns (bool); }

contract Sel {
    enum Status { Active, Paused }
    struct Pair { uint256 id; string name; }

    function a(uint x) external pure returns (uint) { return x; }
    function b(IERC20 token, Ratio r) external pure returns (uint8) { return Ratio.unwrap(r) + uint8(uint160(address(token)) & 0); }
    function c(Status s) external pure returns (uint8) { return uint8(s); }
    function d(Pair calldata p) external pure returns (uint256) { return p.id; }
    function e(uint256[] calldata xs, bytes32 k) external pure returns (uint256) { return xs.length + uint256(k) * 0; }

    function forms() external pure returns (bytes4, bytes4, bytes4, bytes4) {
        return (
            this.a.selector,
            Sel.a.selector,
            IERC20.transfer.selector,
            bytes4(keccak256("a(uint256)"))
        );
    }
    function typo() external pure returns (bytes4, bytes4) {
        return (bytes4(abi.encodeWithSignature("a(uint)", 1)), bytes4(abi.encodeWithSignature("a(uint256)", 1)));
    }
    function sig() external pure returns (bytes4) { return msg.sig; }
}
