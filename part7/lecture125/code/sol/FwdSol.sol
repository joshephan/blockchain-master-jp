// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract FwdSol {
    address immutable impl;

    constructor(address i) {
        impl = i;
    }

    fallback() external payable {
        address t = impl;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), t, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(ok) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}
