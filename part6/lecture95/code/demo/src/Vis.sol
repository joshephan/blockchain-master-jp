// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Vis {
    uint256 private secret = 42;
    uint256 internal inner = 7;
    uint256 public open = 1;

    function ext() external pure returns (uint256) { return 1; }
    function pub() public pure returns (uint256) { return 2; }
    function intl() internal pure returns (uint256) { return 3; }
    function priv() private pure returns (uint256) { return 4; }

    function callAll() external view returns (uint256) {
        return pub() + intl() + priv() + this.ext();
    }
}

contract Child is Vis {
    function useInternal() external pure returns (uint256) {
        return intl();
    }
}
