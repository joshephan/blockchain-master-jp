// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Tree {
    /// @notice Returns the amount of leaves the tree has.
    /// @dev Returns only a fixed number.
    function leaves() external virtual pure returns(uint256) { return 2; }
}
contract Plant {
    function leaves() external virtual pure returns(uint256) { return 3; }
}
contract K1 is Tree, Plant {
    function leaves() external override(Tree, Plant) pure returns(uint256) { return 3; }
}
contract K2 is Tree, Plant {
    /// @inheritdoc Tree
    function leaves() external override(Tree, Plant) pure returns(uint256) { return 3; }
}
contract K3 is Tree {
    function leaves() external override pure returns(uint256) { return 3; }
}
