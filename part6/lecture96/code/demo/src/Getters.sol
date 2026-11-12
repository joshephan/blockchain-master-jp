// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Getters {
    struct Item {
        uint256 price;
        string name;
        uint256[] history;
        mapping(address => bool) liked;
        bool sold;
    }

    uint256 public count = 3;
    uint256[] public list;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    Item public item;
    string public title = "market";
    uint256 public constant FEE = 30;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
        list.push(10); list.push(20); list.push(30);
        balanceOf[msg.sender] = 500;
        item.price = 99; item.name = "pen"; item.history.push(1); item.sold = true;
    }

    function readInside() external view returns (uint256, uint256) {
        return (count, this.count());
    }
}
