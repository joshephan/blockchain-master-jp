// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
interface I {
    /// @notice n-a
    /// @return r-a
    function a() external view returns (uint256);
    /// @notice n-b
    /// @return r-b
    function b() external view returns (uint256);
    /// @notice n-c
    /// @param k p-k
    /// @return r-c
    function c(uint256 k) external view returns (uint256);
}
abstract contract Base is I {
    uint256 public a;
}
contract S1 is Base {
    uint256 public immutable b = 1;
    mapping(uint256 k => uint256) public c;
}
contract S2 is I {
    uint256 public a;
    /// @inheritdoc I
    uint256 public immutable b = 1;
    /// @inheritdoc I
    mapping(uint256 k => uint256) public c;
}
contract S3 is I {
    /// @notice own-a
    /// @return own-r
    uint256 public a;
    /// @dev own-dev
    uint256 public b;
    mapping(uint256 k => uint256) public c;
}
