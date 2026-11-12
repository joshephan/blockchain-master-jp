object "Tally" {
    code {
        sstore(1, caller())
        let size := datasize("Tally_deployed")
        datacopy(0, dataoffset("Tally_deployed"), size)
        return(0, size)
    }
    object "Tally_deployed" {
        code {
            switch shr(224, calldataload(0))
            case 0x06661abd {
                // count()
                mstore(0, sload(0))
                return(0, 0x20)
            }
            case 0x68110b2f {
                // bump(): Bumped(uint256)ログ
                let n := add(sload(0), 1)
                sstore(0, n)
                mstore(0, n)
                log1(0, 0x20, 0xc081b7755956fdb9d6a5482bb04a62dbb62ad944141e7ff6ff2adad34bb1efb9)
                return(0, 0)
            }
            case 0x8da5cb5b {
                // owner()
                mstore(0, sload(1))
                return(0, 0x20)
            }
            case 0x13af4035 {
                // setOwner(address): オーナーでなければNotOwner()
                if iszero(eq(caller(), sload(1))) {
                    mstore(0, shl(224, 0x30cd7471))
                    revert(0, 4)
                }
                sstore(1, calldataload(4))
                return(0, 0)
            }
            default { revert(0, 0) }
        }
    }
}
