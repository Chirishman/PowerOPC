Function Send-OpenPixelControlCommand {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [byte]$Channel = 0,
        [Parameter()]
        [ValidateSet('8BitColor','16BitColor','SystemSpecific')]
        [string]$Command = '8BitColor',
        [Parameter(Mandatory)]
        [System.Drawing.Color[]]$Color,
        [Parameter(Mandatory)]
        [Net.Security.NegotiateStream]$Session
    )

    $TCPMessage = @{
        Data = $null
        Session = $Session
    }

    $CommandLookup = @{
        '8BitColor' = [convert]::ToByte(0)
        '16BitColor' = [convert]::ToByte(1)
        'SystemSpecific' = [convert]::ToByte(255)
    }

    #Split color values into bytes
    [Byte[]]$ColorBytes = $Color | %{
        [byte[]]($_.R,$_.G,$_.B)
    }
    #Convert the data's length into a byte array
    [byte[]]$LengthBytes = [System.BitConverter]::GetBytes([uint16]$ColorBytes.Count)
    #Reverse the byte array's endianness (from default Little Endian to required Big Endian)
    [Array]::Reverse($LengthBytes)

    @(
        #Send Channel Selection
        $Channel,
        #Send Command Selection
        $CommandLookup[$Command],
        #Send Message Length Info
        $LengthBytes,
        #Send Payload Data
        $ColorBytes
    ) | %{
        $TCPMessage.Data = $_
        Send-TCPBytes @TCPMessage
    }
}