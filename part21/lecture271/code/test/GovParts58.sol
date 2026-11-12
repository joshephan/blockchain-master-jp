// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Governor} from "../vendor/oz/governance/Governor.sol";
import {GovernorSettings} from "../vendor/oz/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "../vendor/oz/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "../vendor/oz/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "../vendor/oz/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "../vendor/oz/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "../vendor/oz/governance/TimelockController.sol";
import {IVotes} from "../vendor/oz/governance/utils/IVotes.sol";
import {ERC20} from "../vendor/oz/token/ERC20/ERC20.sol";
import {ERC20Permit} from "../vendor/oz/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "../vendor/oz/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "../vendor/oz/utils/Nonces.sol";


// ガバナー: 投票の遅延・期間・提案のしきい値・定足数をデプロイ引数で受け取る。可決した提案はタイムロックの待機後に実行
contract Gov58 is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(IVotes token, TimelockController timelock, uint48 delay, uint32 period, uint256 threshold, uint256 quorumPct)
        Governor("Gov58")
        GovernorSettings(delay, period, threshold)
        GovernorVotes(token)
        GovernorVotesQuorumFraction(quorumPct)
        GovernorTimelockControl(timelock)
    {}

    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}


// 投票トークン: 票は委任した後から数える、ブロックごとに記録(チェックポイント)
contract GovToken is ERC20, ERC20Permit, ERC20Votes {
    constructor(uint256 supply) ERC20("Gov Token", "GOV") ERC20Permit("Gov Token") {
        _mint(msg.sender, supply);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
