// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第178講: テスト用のマルチシグ。複数人で分けて握る管理者の席。提案一つに署名者threshold人が承認すると実行
contract MultiSigAdmin {
    error BadThreshold(uint256 threshold, uint256 owners);
    error BadOwner(address owner);
    error NotOwner(address caller);
    error NotSelf(address caller);
    error UnknownProposal(uint256 id);
    error AlreadyApproved(uint256 id, address owner);
    error BelowThreshold(uint256 id, uint256 approvals);
    error AlreadyExecuted(uint256 id);
    error CallFailed(uint256 id);

    struct Proposal {
        address target;
        bytes data;
        uint256 approvals;
        bool executed;
    }

    uint256 public immutable threshold;
    address[] public owners;
    mapping(address who => bool) public isOwner;
    Proposal[] public proposals;
    mapping(uint256 id => mapping(address owner => bool)) public approved;

    constructor(address[] memory owners_, uint256 threshold_) {
        if (threshold_ == 0 || threshold_ > owners_.length) revert BadThreshold(threshold_, owners_.length);
        for (uint256 i = 0; i < owners_.length; i++) {
            address o = owners_[i];
            if (o == address(0) || isOwner[o]) revert BadOwner(o);
            isOwner[o] = true;
            owners.push(o);
        }
        threshold = threshold_;
    }

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner(msg.sender);
        _;
    }

    // 何を呼ぶか(対象とデータ)を先に書く。承認はこの提案一つだけに結び付く
    function propose(address target, bytes calldata data) external onlyOwner returns (uint256 id) {
        id = proposals.length;
        proposals.push(Proposal({target: target, data: data, approvals: 0, executed: false}));
    }

    function approve(uint256 id) external onlyOwner {
        if (id >= proposals.length) revert UnknownProposal(id);
        if (approved[id][msg.sender]) revert AlreadyApproved(id, msg.sender);
        approved[id][msg.sender] = true;
        proposals[id].approvals += 1;
    }

    function execute(uint256 id) external onlyOwner {
        if (id >= proposals.length) revert UnknownProposal(id);
        Proposal storage p = proposals[id];
        if (p.executed) revert AlreadyExecuted(id);
        if (p.approvals < threshold) revert BelowThreshold(id, p.approvals);
        p.executed = true;
        (bool ok,) = p.target.call(p.data);
        if (!ok) revert CallFailed(id);
    }

    // 失くした鍵一つを新しい鍵に替える。このコントラクト自身だけが呼ぶ(提案・承認・実行を経る)
    function replaceOwner(address oldOwner, address newOwner) external {
        if (msg.sender != address(this)) revert NotSelf(msg.sender);
        if (!isOwner[oldOwner]) revert BadOwner(oldOwner);
        if (newOwner == address(0) || isOwner[newOwner]) revert BadOwner(newOwner);
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == oldOwner) owners[i] = newOwner;
        }
        isOwner[oldOwner] = false;
        isOwner[newOwner] = true;
    }

    function ownerCount() external view returns (uint256) {
        return owners.length;
    }
}
