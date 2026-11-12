// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ファイルレベルのエラー
error Unauthorized(address caller);

interface IVault {
    error Short(uint256 have, uint256 want);
    error Closed();
    function take(uint256 want) external;
}

library Lib {
    error LibFail(uint8 code);
    function check(uint8 c) internal pure {
        if (c != 0) revert LibFail(c);
    }
}

contract Vault {
    error Short(uint256 have, uint256 want);
    error Closed();
    error Why(string reason);
    error Unused(uint256 x);

    uint256 public have = 3;
    bool public closed;
    address public owner = msg.sender;

    function take(uint256 want) external {
        if (closed) revert Closed();
        if (want > have) revert Short(have, want);
        have -= want;
    }
    function takeReq(uint256 want) external {
        require(want <= have, Short(have, want));
        have -= want;
    }
    function why() external pure { revert Why("closed today"); }
    function onlyOwner() external view { if (msg.sender != owner) revert Unauthorized(msg.sender); }
    function lib(uint8 c) external pure { Lib.check(c); }
    function close() external { closed = true; }

    function shortSel() external pure returns (bytes4) { return Short.selector; }
    function shortEnc() external view returns (bytes memory) { return abi.encodeWithSelector(Short.selector, have, 5); }
}

// 受け取る側
contract Taker {
    bytes public last;
    bytes4 public lastSel;
    uint256 public shortCount;
    function tryTake(IVault v, uint256 want) external {
        try v.take(want) {
        } catch (bytes memory data) {
            last = data;
            lastSel = bytes4(data);
            if (bytes4(data) == IVault.Short.selector) shortCount += 1;
        }
    }
    function plain(IVault v, uint256 want) external {
        v.take(want);
    }

    // 受け取ったバイト列から引数をほどく: memory bytesは切り出せないのでcalldataで渡して先頭4バイトを外す
    uint256 public lastHave;
    uint256 public lastWant;
    function tryTakeArgs(IVault v, uint256 want) external {
        try v.take(want) {
        } catch (bytes memory data) {
            if (bytes4(data) == IVault.Short.selector) (lastHave, lastWant) = this.shortArgs(data);
        }
    }
    function shortArgs(bytes calldata data) external pure returns (uint256 have, uint256 want) {
        return abi.decode(data[4:], (uint256, uint256));
    }
}
