// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Membership {
    mapping(address => uint256) public grade;

    function join(address user) external {
        grade[user] = 1;
    }

    function discount(address user) external view returns (uint256) {
        require(grade[user] > 0, "not a member");
        return 10;
    }
}

contract Payment {
    Membership public m;
    event PayRequested(address user, uint256 price);

    constructor(Membership _m) {
        m = _m;
    }

    function pay(address user, uint256 price) external returns (uint256) {
        emit PayRequested(user, price);
        uint256 d = m.discount(user);
        return price - price * d / 100;
    }
}

contract Points {
    function add(address) external pure {
        revert("points closed");
    }
}

contract Shop {
    Payment public p;
    Points public pts;
    uint256 public orders;

    constructor(Payment _p, Points _pts) {
        p = _p;
        pts = _pts;
    }

    function order(uint256 price) external returns (uint256) {
        orders += 1;
        return p.pay(msg.sender, price);
    }

    function orderWithPoints(uint256 price) external returns (uint256) {
        orders += 1;
        address(pts).call(abi.encodeCall(Points.add, (msg.sender)));
        return p.pay(msg.sender, price);
    }
}
