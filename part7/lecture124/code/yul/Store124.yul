object "Store" {
    code {
        sstore(0, 7)
        let size := datasize("Store_deployed")
        datacopy(0, dataoffset("Store_deployed"), size)
        return(0, size)
    }
    object "Store_deployed" {
        code {
            switch shr(224, calldataload(0))
            case 0x6d4ce63c { mstore(0, sload(0)) return(0, 0x20) }
            case 0x60fe47b1 { sstore(0, calldataload(4)) return(0, 0) }
            case 0x26d111f5 {
                let n := datasize("Note")
                datacopy(0, dataoffset("Note"), n)
                return(0, n)
            }
            default { revert(0, 0) }
        }
        data "Note" "Store124"
    }
}
