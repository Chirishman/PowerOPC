Function Read-TCPBytes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
		[int]$Length,
		[Parameter(Mandatory)]
        [Net.Security.NegotiateStream]$Session
    )

    $ArrayList = [System.Collections.ArrayList]::new()

    [byte[]]$byte = New-Object byte[] $Length
    Write-Verbose ("{0} Bytes Left" -f $client.Available)
    $bytesReceived = $Session.Read($byte, 0, $byte.Length)
    If ($bytesReceived -gt 0) {
        Write-Verbose ("{0} Bytes received" -f $bytesReceived)
        #[void]$stringBuilder.Append([text.Encoding]::Ascii.GetString($byte[0..($bytesReceived - 1)]))
        [void]$ArrayList.Add(($byte[0..($bytesReceived - 1)]))
    } Else {
        $activeConnection = $False
        Break
    }

    $ArrayList
    $byte.Clear()
}