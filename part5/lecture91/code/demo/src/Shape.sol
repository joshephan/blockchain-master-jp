// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IPing {
    function ping() external;
}

// transferFromが何も返さないトークン
contract NoReturnToken {
    function transferFrom(address, address, uint256) external {}
}

contract Puller {
    event Result(string path);

    function pull(address token) external {
        try IERC20(token).transferFrom(msg.sender, address(this), 1) returns (bool ok) {
            emit Result(ok ? "returns true" : "returns false");
        } catch {
            emit Result("catch");
        }
    }

    function ping(address target) external {
        try IPing(target).ping() {
            emit Result("returns");
        } catch {
            emit Result("catch");
        }
    }
}
