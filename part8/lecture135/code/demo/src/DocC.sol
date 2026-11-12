// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.29;

struct S {
    int32 x;
    bool y;
}

contract A {
    uint a;
    uint128 transient b;
    uint constant c = 10;
    uint immutable d = 12;
}

contract B {
    uint8[] e;
    mapping(uint => S) f;
    uint16 g;
    uint16 h;
    bytes16 transient i;
    S s;
    int8 k;
}

contract C is A, B layout at 42 {
    bytes21 l;
    uint8[10] m;
    bytes5[8] n;
    bytes5 o;
}
