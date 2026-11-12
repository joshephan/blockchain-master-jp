// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
import "../src/Layout135.sol";

contract Layout135Test is Test {
    function test_docC() public {
        CFill c = new CFill();
        (uint256 tb, uint256 ti) = c.fill();
        console.log("tload(0) inside fill:");
        console.logBytes32(bytes32(tb));
        for (uint256 p = 42; p <= 51; p++) {
            console.log(p);
            console.logBytes32(vm.load(address(c), bytes32(p)));
        }
        bytes32 eData = keccak256(abi.encode(uint256(43)));
        console.log("e data at keccak(43):");
        console.logBytes32(vm.load(address(c), eData));
        bytes32 f1 = keccak256(abi.encode(uint256(1), uint256(44)));
        console.log("f[1] at keccak(1 . 44):");
        console.logBytes32(vm.load(address(c), f1));
        console.log("slot 0 storage (should be 0):");
        console.logBytes32(vm.load(address(c), bytes32(0)));
    }

    function test_docData() public {
        DocData d = new DocData();
        d.put();
        bytes32 inner = keccak256(abi.encode(uint256(4), uint256(1)));
        bytes32 base = keccak256(abi.encode(uint256(9), inner));
        console.log("data[4][9] base slot:");
        console.logBytes32(base);
        console.logBytes32(vm.load(address(d), base));
        console.logBytes32(vm.load(address(d), bytes32(uint256(base) + 1)));
    }

    function test_strKey() public {
        StrKey s = new StrKey();
        s.put();
        bytes32 slot = keccak256(abi.encodePacked("abc", uint256(1)));
        bytes32 padded = keccak256(abi.encode("abc", uint256(1)));
        console.log("keccak(abc . 1) unpadded slot value:");
        console.logBytes32(slot);
        console.logBytes32(vm.load(address(s), slot));
        console.log("abi.encode slot value:");
        console.logBytes32(vm.load(address(s), padded));
    }

    function test_nested24() public {
        Nested24 n = new Nested24();
        n.put();
        bytes32 outer = keccak256(abi.encode(uint256(0)));
        bytes32 row1 = keccak256(abi.encode(uint256(outer) + 1));
        console.log("x length slot0, x[1] length at keccak(0)+1:");
        console.logBytes32(vm.load(address(n), bytes32(0)));
        console.logBytes32(vm.load(address(n), bytes32(uint256(outer) + 1)));
        console.log("x[1] data slot +0 and +1:");
        console.logBytes32(vm.load(address(n), row1));
        console.logBytes32(vm.load(address(n), bytes32(uint256(row1) + 1)));
        uint256 j = 11;
        uint256 v = uint256(vm.load(address(n), bytes32(uint256(row1) + j / 10)));
        console.log("formula x[1][11]:", (v >> ((j % 10) * 24)) & type(uint24).max);
        console.log("getter x[1][11]:", n.get(1, 11));
    }

    function test_str() public {
        Str135 s = new Str135();
        s.put();
        console.logBytes32(vm.load(address(s), bytes32(0)));
        console.logBytes32(vm.load(address(s), bytes32(uint256(1))));
        bytes32 d = keccak256(abi.encode(uint256(1)));
        console.logBytes32(vm.load(address(s), d));
        console.logBytes32(vm.load(address(s), bytes32(uint256(d) + 1)));
    }

    function test_badStr() public {
        BadStr b = new BadStr();
        b.poke(3);
        try b.len() returns (uint256 l) { console.log("len ok", l); } catch (bytes memory r) { console.log("len revert"); console.logBytes(r); }
        try b.read() returns (string memory s) { console.log("read ok", bytes(s).length); } catch (bytes memory r) { console.log("read revert"); console.logBytes(r); }
    }
}
