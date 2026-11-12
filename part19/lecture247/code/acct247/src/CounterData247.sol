// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// データアカウントのまね: 値だけを置き、ownerとして書かれたプログラムだけが直せる
contract CounterData247 {
    error NotOwner(address caller);

    address public immutable owner;
    uint64 public count;

    constructor(address owner_) {
        owner = owner_;
    }

    function write(uint64 value) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        count = value;
    }
}
