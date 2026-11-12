// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ev141 {
    struct S { string a; uint256 b; }
    struct D { uint256[] a; uint256[] b; }
    event Arr(uint256[] indexed xs);
    event Str(string indexed s);
    event St(S indexed s);
    event Dd(D indexed d);
    event Neg(int8 indexed x, int8 y);
    event Both(string indexed key, string key2);
    event Anon(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 indexed d) anonymous;

    function arr(uint256[] calldata xs) external { emit Arr(xs); }
    function str(string calldata s) external { emit Str(s); }
    function st(S calldata s) external { emit St(s); }
    function dd(D calldata d) external { emit Dd(d); }
    function neg() external { emit Neg(-1, -1); }
    function both(string calldata s) external { emit Both(s, s); }
    function anon() external { emit Anon(1, 2, 3, 4); }
}
