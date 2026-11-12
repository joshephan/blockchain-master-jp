// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface INotify {
    function notify(uint256 amount) external;
}

contract Token is IERC20 {
    mapping(address => uint256) public override balanceOf;

    constructor() {
        balanceOf[msg.sender] = 1000;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract FakeToken {
    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 1000000;
    }
}

contract Pool {
    IERC20 public asset;

    constructor(IERC20 a) {
        asset = a;
    }

    function assetAddress() external view returns (address) {
        return address(asset);
    }

    function selfAddress() external view returns (address) {
        return address(this);
    }

    function pay(address to, uint256 amount) external returns (bool) {
        return asset.transfer(to, amount);
    }
}

contract Prober {
    function withReturn(address a) external returns (bool) {
        return IERC20(a).transfer(address(0xB0b), 1);
    }

    function noReturn(address a) external {
        INotify(a).notify(1);
    }

    function lowLevel(address a) external returns (bool ok, bytes memory data) {
        (ok, data) = a.call(abi.encodeWithSelector(IERC20.transfer.selector, address(0xB0b), 1));
    }

    function codeLength(address a) external view returns (uint256) {
        return a.code.length;
    }
}
