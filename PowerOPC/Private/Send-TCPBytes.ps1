Function Send-TCPBytes {
    [CmdletBinding()]
    Param(
        [Byte[]]$Data,
        [Net.Security.NegotiateStream]$Session
    )

    Write-Verbose "Sending $($Data.count) bytes"
    $Session.Write($Data,0,$Data.length)
    $Session.Flush()
}