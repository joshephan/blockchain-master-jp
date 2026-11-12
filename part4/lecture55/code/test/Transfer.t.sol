// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Sender} from "../src/Sender.sol";
import {NoReceive, Writer, Refuser, Probe} from "../src/Receivers.sol";

contract TransferTest is Test {
    Sender s;
    address[3] to;
    string[3] names = ["NoReceive", "Writer", "Refuser"];

    function setUp() public {
        s = new Sender{value: 100 ether}();
        to[0] = address(new NoReceive());
        to[1] = address(new Writer());
        to[2] = address(new Refuser());
    }

    // 関数全体が巻き戻ったか、返ってきたboolが何か、次の行が実行されたか
    function _try(bytes memory data) internal returns (string memory) {
        uint256 before = s.reached();
        (bool whole, bytes memory ret) = address(s).call(data);
        if (!whole) return "revert (whole function)";
        bool ok = true;
        if (ret.length == 32) ok = abi.decode(ret, (bool));
        bool next = s.reached() == before + 1;
        return string.concat(
            ok ? "ok=true" : "ok=false",
            next ? ", next line ran" : ", next line skipped"
        );
    }

    function test_Table() public {
        for (uint256 i = 0; i < 3; i++) {
            console.log(names[i]);
            console.log("  transfer:", _try(abi.encodeCall(Sender.viaTransfer, (payable(to[i])))));
            console.log("  send    :", _try(abi.encodeCall(Sender.viaSend, (payable(to[i])))));
            console.log("  call    :", _try(abi.encodeCall(Sender.viaCall, (to[i]))));
        }
    }

    function test_GasGiven() public {
        address p = address(new Probe());
        s.viaTransfer(payable(p));
        s.viaSend(payable(p));
        s.viaCall(p);
    }

    function test_RevertWhen_WriterViaTransfer() public {
        vm.expectRevert();
        s.viaTransfer(payable(to[1]));
    }

    function test_WriterViaCall() public {
        s.viaCall(to[1]);
    }
}
