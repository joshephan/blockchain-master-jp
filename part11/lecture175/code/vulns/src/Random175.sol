// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第175講のトイの抽選。ブロックの値で当選を決める。誰でも同じブロックで同じ値を前もって計算できる
contract BadLottery {
    uint256 public immutable modulus;

    constructor(uint256 m) {
        modulus = m;
    }

    // 当選番号 = ブロックの値をいくつか混ぜたハッシュをmodulusで割った余り
    function draw() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp))) % modulus;
    }

    // 選んだ番号が合えば当選。外れれば巻き戻す(トークンの支払いは最小の形なので省略)
    function play(uint256 guess) external view returns (bool) {
        if (guess != draw()) revert Missed();
        return true;
    }

    // まだ作られていないブロックのハッシュは0
    function futureHash() external view returns (bytes32) {
        return blockhash(block.number);
    }

    error Missed();
}

// 第175講のトイのコミット・リビール。参加者がまず秘密をハッシュでロックし、後で一緒に開いて混ぜる
contract CommitReveal {
    struct Entry {
        bytes32 commit;
        bool revealed;
    }

    mapping(address => Entry) public entries;
    uint256 public seed;
    uint256 public revealCount;

    // 段階1: keccak256(秘密, アドレス)だけを上げる。秘密はまだ見えない
    function commit(bytes32 h) external {
        entries[msg.sender] = Entry({commit: h, revealed: false});
    }

    // 段階2: 秘密を開き、上げておいたハッシュと合うかを確認してから混ぜる
    function reveal(uint256 secret) external {
        Entry storage e = entries[msg.sender];
        if (e.commit != keccak256(abi.encodePacked(secret, msg.sender))) revert BadReveal();
        if (e.revealed) revert AlreadyRevealed();
        e.revealed = true;
        seed ^= secret;
        revealCount++;
    }

    function result(uint256 modulus) external view returns (uint256) {
        return seed % modulus;
    }

    error BadReveal();
    error AlreadyRevealed();
}
