// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// EIP-2535の形を縮めたダイヤモンド。diamondCut・facetAddress・ownerはダイヤモンドに直接書いた関数(変えられない)
contract MiniDiamond {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // セレクター表と持ち主を置いた欄。開始スロットは文字列ハッシュ
    struct DiamondStorage {
        mapping(bytes4 => address) facetOf;
        address owner;
    }

    bytes32 internal constant DS_SLOT = keccak256("mini.diamond.storage");

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    function ds() internal pure returns (DiamondStorage storage s) {
        bytes32 slot = DS_SLOT;
        assembly {
            s.slot := slot
        }
    }

    constructor(address owner_) {
        ds().owner = owner_;
    }

    function owner() external view returns (address) {
        return ds().owner;
    }

    function facetAddress(bytes4 selector) external view returns (address) {
        return ds().facetOf[selector];
    }

    function diamondCut(FacetCut[] calldata cuts, address init, bytes calldata data) external {
        DiamondStorage storage s = ds();
        require(msg.sender == s.owner, "not owner");
        for (uint256 i = 0; i < cuts.length; i++) {
            FacetCut calldata c = cuts[i];
            for (uint256 j = 0; j < c.functionSelectors.length; j++) {
                bytes4 sel = c.functionSelectors[j];
                address cur = s.facetOf[sel];
                if (c.action == FacetCutAction.Add) {
                    require(cur == address(0), "selector exists");
                    s.facetOf[sel] = c.facetAddress;
                } else if (c.action == FacetCutAction.Replace) {
                    require(cur != address(0) && cur != c.facetAddress, "bad replace");
                    s.facetOf[sel] = c.facetAddress;
                } else {
                    require(cur != address(0), "not found");
                    delete s.facetOf[sel];
                }
            }
        }
        emit DiamondCut(cuts, init, data);
        if (init != address(0)) {
            (bool ok,) = init.delegatecall(data);
            require(ok, "init failed");
        }
    }

    fallback() external {
        address facet = ds().facetOf[msg.sig];
        require(facet != address(0), "no facet");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
