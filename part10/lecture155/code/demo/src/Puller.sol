// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IToken {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// 承認されたコントラクトがfromを引数で受け取る形(デモ用)。誰が呼んでもfromの承認を使う
contract Puller {
    function pull(IToken token, address from, uint256 value) external {
        require(token.transferFrom(from, msg.sender, value), "pull failed");
    }
}

// 同じことを、呼んだ人自身のものだけを移す形(Marketのdepositと同じ形)
contract SelfPuller {
    mapping(address => uint256) public held;

    function pullMine(IToken token, uint256 value) external {
        held[msg.sender] += value;
        require(token.transferFrom(msg.sender, address(this), value), "pull failed");
    }
}
