// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 自分の欄を文字列ハッシュのスロットに置いたファセット(facet)
contract CounterFacet {
    struct CounterStorage {
        uint256 count;
    }

    bytes32 internal constant SLOT = keccak256("mini.counter.storage");

    function cs() internal pure returns (CounterStorage storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }

    function inc() external {
        cs().count += 1;
    }

    function count() external view returns (uint256) {
        return cs().count;
    }
}

// 同じ欄を使う二つ目の版。一回に10
contract CounterFacetV2 {
    struct CounterStorage {
        uint256 count;
    }

    bytes32 internal constant SLOT = keccak256("mini.counter.storage");

    function cs() internal pure returns (CounterStorage storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }

    function inc() external {
        cs().count += 10;
    }
}

// 普通の状態変数を使った二つのファセット。両方ともスロット0
contract RateFacet {
    uint256 public rate; // スロット0

    function setRate(uint256 r) external {
        rate = r;
    }
}

contract TreasuryFacet {
    address public treasury; // スロット0

    function setTreasury(address t) external {
        treasury = t;
    }
}

// セレクター0x42966c68を使う二つのファセット
contract BurnFacet {
    event Burned(uint256 amount);

    function burn(uint256 amount) external {
        emit Burned(amount);
    }
}

contract CollateFacet {
    event Collated();

    function collate_propagate_storage(bytes16) external {
        emit Collated();
    }
}
