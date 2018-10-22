function Start-OpenPixelControlListener {
    [CmdletBinding()]
    Param(
        [int]$port = 1655
    )
	
    $Session = $Global:OpenPixelControlListenerSession | Where-Object {$_.Port -eq $port}
	
    if (-not $Session) {
        New-OpenPixelControlServerSession -Port $port
        $Session = $Global:OpenPixelControlListenerSession | Where-Object {$_.Port -eq $port}
    }

    $Message = Read-TCPBytes -Length ([int]([uint16]::MaxValue)) -Session $Session.Session

    $Header = @{
        Channel = [int]$Message[0]
        Command = [int]$Message[1]
        Length  = $(
            $Length = $Message[2, 3]
            [Array]::Reverse($Length)
            [bitconverter]::ToUInt16($Length, 0)
        )
    }

    $ColorStream = $Message[4..(4 + $Header.Length - 1)]

    $ColorCount = $ColorStream.Count / 3

    New-Object -TypeName PSObject -Property ([ordered]@{
            Channel    = $Header.Channel
            Command    = $Header.Command
            ColorArray = $(
                (
                    0..($ColorCount - 1) | ForEach-Object {
                        $ThisColor = $ColorStream[(0 + (3 * $_))..((3 + (3 * $_)) - 1)]
                        [System.Drawing.Color]::FromArgb($ThisColor[0], $ThisColor[1], $ThisColor[2])
                    }
                )
            )
        })

    $Session.Stream.Flush()
    $Session.Session.Flush()
    
    $Message.Clear()
    
    #Write-Verbose "Closing session to $remoteClient"
    #$Session.Client.Close()
}