object "A" {
    code {
        let s := datasize("A_runtime")
        datacopy(0, dataoffset("A_runtime"), s)
        return(0, s)
    }
    object "A_deployed" {
        code { stop() }
    }
}
