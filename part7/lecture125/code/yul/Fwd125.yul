object "Fwd" {
    code {
        let size := datasize("Fwd_deployed")
        datacopy(0, dataoffset("Fwd_deployed"), size)
        return(0, size)
    }
    object "Fwd_deployed" {
        code {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), 0x5FbDB2315678afecb367f032d93F642f64180aa3, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(ok) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}
