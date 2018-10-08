function Start-OpenPixelControlListener {
    Param(
		[int]$port=1655
    )

	if (-not $Global:OpenPixelControlListenerSession) {
		New-OpenPixelControlServerSession -Port $port
	}

	$Session = $Global:OpenPixelControlListenerSession | ?{$_.Port -eq $port}

    $Header = @{
        Channel = [int](Read-TCPBytes -Length 1 -Session $Session.Session )[0]
        Command = [int](Read-TCPBytes -Length 1 -Session $Session.Session)[0]
        Length = $(
            $Length = Read-TCPBytes -Length 2 -Session $Session.Session
            [Array]::Reverse($Length)
            [bitconverter]::ToUInt16($Length,0)
        )
    }

    $ColorStream = Read-TCPBytes -Length $Header.Length -Session $Session.Session

    $ColorCount = $ColorStream.Count / 3

    (
        0..($ColorCount - 1) | %{
            $ThisColor = $ColorStream[(0 + (3 * $_))..((3 + (3 * $_)) - 1)]
            [System.Drawing.Color]::FromArgb($ThisColor[0],$ThisColor[1],$ThisColor[2])
        }
    )
}