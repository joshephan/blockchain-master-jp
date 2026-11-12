// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// アクターの形のまね: 外を呼ばず、送るメッセージを返す
struct Msg249 {
    address target;
    bytes data;
    bool replyOnError;
}

contract Actor249 {
    error OnlyRouter();

    address public immutable router;
    uint256 public a;
    uint256 public b;
    uint256 public replies;
    bool public lastReplyOk;

    constructor(address router_) {
        router = router_;
    }

    function update(address target, bool failing, bool replyOnError) external returns (Msg249[] memory out) {
        if (msg.sender != router) revert OnlyRouter();
        a = 1;
        b = 1;
        out = new Msg249[](1);
        bytes memory data = failing
            ? abi.encodeWithSignature("fail()")
            : abi.encodeWithSignature("ping(address)", address(this));
        out[0] = Msg249(target, data, replyOnError);
    }

    function reply(bool ok) external {
        if (msg.sender != router) revert OnlyRouter();
        replies++;
        lastReplyOk = ok;
    }
}

// チェーン側のまね: 関数が終わったあとメッセージを順に実行。失敗したらreplyOnErrorのときだけreply、そうでなければ全部リバート
contract Router249 {
    error MessageFailed(uint256 index);

    function run(Actor249 actor, address target, bool failing, bool replyOnError) external {
        Msg249[] memory msgs = actor.update(target, failing, replyOnError);
        for (uint256 i = 0; i < msgs.length; i++) {
            (bool ok,) = msgs[i].target.call(msgs[i].data);
            if (!ok) {
                if (!msgs[i].replyOnError) revert MessageFailed(i);
                actor.reply(false);
            }
        }
    }
}
