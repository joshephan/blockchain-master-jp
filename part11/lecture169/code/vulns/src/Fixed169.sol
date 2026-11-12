// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第169講の直した版。Vault169.solの二つの金庫と関数の形は同じで、順番だけを変える(帳簿が先、送るのは後)

contract ShareVaultCei {
    mapping(address => uint256) public shares;

    function deposit() external payable {
        shares[msg.sender] += msg.value;
    }

    function transferShares(address to, uint256 amount) external {
        require(shares[msg.sender] >= amount, "too much");
        shares[msg.sender] -= amount;
        shares[to] += amount;
    }

    function withdraw() external {
        uint256 amount = shares[msg.sender];
        shares[msg.sender] = 0; // 先に0に
        (bool ok,) = msg.sender.call{value: amount}(""); // 後で送る
        require(ok, "send failed");
    }
}

contract PricedVaultCei {
    mapping(address => uint256) public sharesOf;
    uint256 public totalShares;

    function mint() external payable {
        sharesOf[msg.sender] += msg.value;
        totalShares += msg.value;
    }

    function price() public view returns (uint256) {
        if (totalShares == 0) return 0;
        return (address(this).balance * 1e18) / totalShares;
    }

    function redeem() external {
        uint256 s = sharesOf[msg.sender];
        sharesOf[msg.sender] = 0;
        totalShares -= s; // 供給を先に減らす
        (bool ok,) = msg.sender.call{value: s}(""); // イーサは後で
        require(ok, "send failed");
    }
}
