// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第206講: コミット・リビールの抽選。コミット時に保証金1 ether、リビールの締め切り内に開いた人だけが返してもらえて当選候補になる
// 開かなかった人の保証金は当選者へ。開いた秘密を順番に混ぜてシードを作る
contract CommitRaffle {
    uint256 public constant DEPOSIT = 1 ether;
    uint256 public immutable commitEnd;
    uint256 public immutable revealEnd;
    mapping(address who => bytes32) public commits;
    mapping(address who => bool) public revealed;
    address[] public revealers;
    bytes32 public seed;
    address public winner;

    error WrongPhase(uint256 at, uint256 from, uint256 to);
    error BadDeposit(uint256 value);
    error AlreadyCommitted();
    error BadReveal();

    constructor(uint256 commitSeconds, uint256 revealSeconds) {
        commitEnd = block.timestamp + commitSeconds;
        revealEnd = commitEnd + revealSeconds;
    }

    function hashOf(address who, uint256 secret, bytes32 salt) public pure returns (bytes32) {
        return keccak256(abi.encode(who, secret, salt));
    }

    function commit(bytes32 h) external payable {
        if (block.timestamp >= commitEnd) revert WrongPhase(block.timestamp, 0, commitEnd);
        if (msg.value != DEPOSIT) revert BadDeposit(msg.value);
        if (commits[msg.sender] != 0) revert AlreadyCommitted();
        commits[msg.sender] = h;
    }

    function reveal(uint256 secret, bytes32 salt) external {
        if (block.timestamp < commitEnd || block.timestamp >= revealEnd) {
            revert WrongPhase(block.timestamp, commitEnd, revealEnd);
        }
        if (revealed[msg.sender] || commits[msg.sender] != hashOf(msg.sender, secret, salt)) revert BadReveal();
        revealed[msg.sender] = true;
        revealers.push(msg.sender);
        seed = keccak256(abi.encode(seed, secret));
        payable(msg.sender).transfer(DEPOSIT);
    }

    function finalize() external {
        if (block.timestamp < revealEnd) revert WrongPhase(block.timestamp, revealEnd, type(uint256).max);
        require(winner == address(0) && revealers.length > 0);
        winner = revealers[uint256(seed) % revealers.length];
        payable(winner).transfer(address(this).balance);
    }
}
