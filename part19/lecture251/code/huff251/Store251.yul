object "Store251" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            switch shr(224, calldataload(0))
            case 0x55241077 { sstore(0, calldataload(4)) stop() }
            case 0x20965255 { mstore(0, sload(0)) return(0, 32) }
            default { revert(0, 0) }
        }
    }
}
