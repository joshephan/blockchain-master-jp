// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Slot136 {
    uint128 s0;
    uint128 transient b;
    bytes16 transient i;

    function run() external returns (uint bSlot, uint bOff, uint iSlot, uint iOff, uint viaT, uint viaS, bytes16 iAfter) {
        s0 = 7;
        b = 0xbbbb;
        i = 0x99999999999999999999999999999999;
        assembly {
            bSlot := b.slot
            bOff := b.offset
            iSlot := i.slot
            iOff := i.offset
            viaT := tload(b.slot)
            viaS := sload(b.slot)
            tstore(b.slot, 0x1234)
        }
        iAfter = i;
    }
}
