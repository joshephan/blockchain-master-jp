// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ptr {
    function _who() internal view returns (address) {
        return msg.sender;
    }

    function viaInternal() external view returns (address) {
        return _who();
    }

    function ptr() external pure returns (uint256 x) {
        function () internal view returns (address) f = _who;
        assembly { x := f }
    }
}
