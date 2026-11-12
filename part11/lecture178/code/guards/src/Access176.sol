// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

// オーナーは一人。確認はmsg.senderだけで、tx.originは読まない
contract OwnedVault {
    error NotOwner(address caller);

    address public immutable owner;
    bool public paused;

    constructor(address owner_) {
        owner = owner_;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    function pause() external onlyOwner {
        paused = true;
    }
}

// 役割を二つに分ける。止める人と役割を与える人が違う
contract RoleVault is AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bool public paused;

    constructor(address roleAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        paused = true;
    }
}

// オーナーの譲渡は二段階。受け取る側がacceptOwnershipを呼ばなければ移らない
contract HandoverVault is Ownable2Step {
    constructor(address owner_) Ownable(owner_) {}
}
