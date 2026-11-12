object "A" {
    code {
        let s := datasize("A_deployed")
        datacopy(0, dataoffset("A_deployed"), s)
        return(0, s)
    }
    object "A_deployed" {
        code { mstore(0, datasize("A")) return(0, 32) }
    }
}
