// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    event Short(uint256 have, uint256 want);
    error Short(uint256 have, uint256 want);
}
