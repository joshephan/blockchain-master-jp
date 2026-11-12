// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第206講: チェーンの外の乱数を要求・応答の二つの取引で受け取る流れの講義用のまね。実在するサービスのコードではない
// 本物のVRF証明の代わりにオラクルの鍵の署名を確認する(署名は同じ入力に対して一つに決まらないので本物のVRFではない)
// 乱数 = 署名のkeccak256。sが大きい側の署名は受け取らない(他人がsを反転させて乱数を変えられないように)
interface IRandomConsumer {
    function rawFulfillRandomWords(uint256 requestId, uint256 word) external;
}

contract MockCoordinator {
    uint256 public constant MIN_CONFIRMATIONS = 3;
    uint256 private constant HALF_N = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
    address public immutable oracle;
    uint256 public nonce;

    struct Request {
        address consumer;
        uint64 blockNumber;
        uint32 gasLimit;
        bool done;
        bytes32 seed;
    }

    mapping(uint256 id => Request) public requests;

    event RandomWordsRequested(uint256 indexed requestId, address indexed consumer, bytes32 seed);
    event RandomWordsFulfilled(uint256 indexed requestId, uint256 word, bool success);

    error UnknownRequest(uint256 requestId);
    error AlreadyFulfilled(uint256 requestId);
    error TooEarly(uint256 have, uint256 want);
    error BadProof();

    constructor(address oracle_) {
        oracle = oracle_;
    }

    function requestRandomWords(uint32 callbackGasLimit) external returns (uint256 requestId) {
        requestId = ++nonce;
        bytes32 seed = keccak256(abi.encode(address(this), block.chainid, requestId, msg.sender));
        requests[requestId] = Request(msg.sender, uint64(block.number), callbackGasLimit, false, seed);
        emit RandomWordsRequested(requestId, msg.sender, seed);
    }

    // オラクルが署名する値
    function digest(uint256 requestId) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), block.chainid, requestId, requests[requestId].seed));
    }

    // 誰が送ってもよい。確認するのは署名だけ。受け取る側がリバートしても呼び直さない(done = true)
    function fulfill(uint256 requestId, bytes calldata sig) external {
        Request storage r = requests[requestId];
        if (r.consumer == address(0)) revert UnknownRequest(requestId);
        if (r.done) revert AlreadyFulfilled(requestId);
        if (block.number < r.blockNumber + MIN_CONFIRMATIONS) {
            revert TooEarly(block.number, r.blockNumber + MIN_CONFIRMATIONS);
        }
        if (sig.length != 65) revert BadProof();
        bytes32 rr = bytes32(sig[0:32]);
        bytes32 ss = bytes32(sig[32:64]);
        uint8 v = uint8(sig[64]);
        if (uint256(ss) > HALF_N) revert BadProof();
        if (ecrecover(digest(requestId), v, rr, ss) != oracle) revert BadProof();
        uint256 word = uint256(keccak256(sig));
        r.done = true;
        (bool ok,) =
            r.consumer.call{gas: r.gasLimit}(abi.encodeCall(IRandomConsumer.rawFulfillRandomWords, (requestId, word)));
        emit RandomWordsFulfilled(requestId, word, ok);
    }
}
