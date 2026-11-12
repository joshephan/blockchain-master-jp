// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IVerifier} from "./Msg57.sol";

// 外部検証の一番小さい形: 確認者(attester)の鍵一つが「向こうから送った」と書いた番号だけが正しい
contract AttesterVerifier is IVerifier {
    error NotAttester(address caller);

    address public immutable attester;
    mapping(bytes32 id => bool) public attested;

    constructor(address attester_) {
        attester = attester_;
    }

    function attest(bytes32 id) external {
        if (msg.sender != attester) revert NotAttester(msg.sender);
        attested[id] = true;
    }

    function verify(bytes32 id, bytes calldata) external view returns (bool) {
        return attested[id];
    }
}

// 楽観的検証: 提案者が上げた番号は異議申し立て期間が過ぎてから正しいとされる。その間に監視者が一人でも止めれば最後まで正しいとされない
contract OptimisticVerifier is IVerifier {
    error ZeroId();
    error NotProposer(address caller);
    error NotWatcher(address caller);
    error AlreadyProposed(bytes32 id);
    error NotProposed(bytes32 id);
    error ChallengeClosed(bytes32 id);

    uint256 public constant WINDOW = 30 minutes;

    address public immutable proposer;
    mapping(address who => bool) public isWatcher;
    mapping(bytes32 id => uint256) public proposedAt;
    mapping(bytes32 id => bool) public challenged;

    constructor(address proposer_, address[] memory watchers) {
        proposer = proposer_;
        for (uint256 i = 0; i < watchers.length; i++) {
            isWatcher[watchers[i]] = true;
        }
    }

    // 番号0は受け取らない。デフォルト値0が「上がってきた番号」と読まれないように
    function propose(bytes32 id) external {
        if (msg.sender != proposer) revert NotProposer(msg.sender);
        if (id == bytes32(0)) revert ZeroId();
        if (proposedAt[id] != 0) revert AlreadyProposed(id);
        proposedAt[id] = block.timestamp;
    }

    function challenge(bytes32 id) external {
        if (!isWatcher[msg.sender]) revert NotWatcher(msg.sender);
        uint256 t = proposedAt[id];
        if (t == 0) revert NotProposed(id);
        if (block.timestamp >= t + WINDOW) revert ChallengeClosed(id);
        challenged[id] = true;
    }

    function verify(bytes32 id, bytes calldata) external view returns (bool) {
        if (id == bytes32(0)) return false;
        uint256 t = proposedAt[id];
        return t != 0 && !challenged[id] && block.timestamp >= t + WINDOW;
    }
}

// ライトクライアントを小さくした形: 向こうのチェーンのバリデーターの3分の2が署名したヘッダーだけを受け取り、メッセージはヘッダーのルートの下の証明で確認
// バリデーターの集合は今の集合の署名でだけ変わる。最初の集合はデプロイ時に決める(出発点)
contract HeaderLightClient is IVerifier {
    error BelowQuorum(uint256 signers, uint256 needed);
    error NotValidator(address signer);
    error SignersNotSorted(address signer);

    uint256 public immutable srcChainId;
    uint256 public epoch;
    mapping(uint256 epoch => mapping(address who => bool)) public isValidator;
    mapping(uint256 epoch => uint256) public setSize;
    mapping(uint256 number => bytes32 root) public messageRootOf;

    constructor(uint256 srcChainId_, address[] memory validators) {
        srcChainId = srcChainId_;
        _setValidators(0, validators);
    }

    // 向こうのチェーンについての事実なので、受け取り側のチェーン番号・アドレスは含めない
    function headerDigest(uint256 number, bytes32 root) public view returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(srcChainId, "header", number, root)));
    }

    function setDigest(uint256 nextEpoch, address[] calldata next) public view returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(srcChainId, "set", nextEpoch, next)));
    }

    function quorum() public view returns (uint256) {
        return setSize[epoch] * 2 / 3 + 1;
    }

    function submitHeader(uint256 number, bytes32 root, bytes[] calldata sigs) external {
        _checkQuorum(headerDigest(number, root), sigs);
        messageRootOf[number] = root;
    }

    function rotate(address[] calldata next, bytes[] calldata sigs) external {
        _checkQuorum(setDigest(epoch + 1, next), sigs);
        epoch++;
        _setValidators(epoch, next);
    }

    // 証明 = (ヘッダー番号、兄弟ハッシュ)。受け取っていないヘッダーはルートが0なので合わない
    function verify(bytes32 id, bytes calldata proof) external view returns (bool) {
        (uint256 number, bytes32[] memory path) = abi.decode(proof, (uint256, bytes32[]));
        bytes32 root = messageRootOf[number];
        if (root == bytes32(0)) return false;
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(id))));
        return MerkleProof.verify(path, root, leaf);
    }

    function _checkQuorum(bytes32 digest, bytes[] calldata sigs) internal view {
        uint256 need = quorum();
        if (sigs.length < need) revert BelowQuorum(sigs.length, need);
        address last = address(0);
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = ECDSA.recover(digest, sigs[i]);
            if (!isValidator[epoch][signer]) revert NotValidator(signer);
            if (signer <= last) revert SignersNotSorted(signer);
            last = signer;
        }
    }

    function _setValidators(uint256 e, address[] memory validators) internal {
        for (uint256 i = 0; i < validators.length; i++) {
            isValidator[e][validators[i]] = true;
        }
        setSize[e] = validators.length;
    }
}
