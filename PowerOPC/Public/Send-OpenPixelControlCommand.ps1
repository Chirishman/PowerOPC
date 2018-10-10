Function Send-OpenPixelControlCommand {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [byte]$Channel = 0,
        [Parameter()]
        [ValidateSet('8BitColor', '16BitColor', 'SystemSpecific')]
        [string]$Command = '8BitColor',
        [Parameter(Mandatory)]
        [System.Drawing.Color[]]$Color,
        [Parameter(Mandatory, ParameterSetName = 'Session')]
        [Net.Security.NegotiateStream]$Session,
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [int]$SessionId,
        [Parameter(Mandatory, ParameterSetName = 'SessionName')]
        [String]$Name
    )

    $TCPMessage = @{
        Data    = $null
        Session = $(
            switch ($PsCmdlet.ParameterSetName) { 
                'Session' { $Session }
                'Id' { $Global:OpenPixelControlSessions | Where-Object {$_.Id -eq $SessionId} | Select-Object -ExpandProperty Session }
                'SessionName' { $Global:OpenPixelControlSessions | Where-Object {$_.Name -eq $Name}  | Select-Object -ExpandProperty Session }
            }
        )
    }

    If (-not $TCPMessage.Session) {
        Write-Error -Message 'No Session Found' -Category ObjectNotFound -ErrorAction Stop
    }

    $CommandLookup = @{
        '8BitColor'      = [convert]::ToByte(0)
        '16BitColor'     = [convert]::ToByte(1)
        'SystemSpecific' = [convert]::ToByte(255)
    }

    #Split color values into bytes
    [Byte[]]$ColorBytes = $Color | ForEach-Object {
        [byte[]]($_.R, $_.G, $_.B)
    }
    #Convert the data's length into a byte array
    [byte[]]$LengthBytes = [System.BitConverter]::GetBytes([uint16]$ColorBytes.Count)
    #Reverse the byte array's endianness (from default Little Endian to required Big Endian)
    [Array]::Reverse($LengthBytes)
    
    #Sort of like the stringbuilder workflow but with binary
    $BinaryWriter = [System.IO.BinaryWriter]::new([System.IO.MemoryStream]::new())
    @(
        $Channel,
        $CommandLookup[$Command],
        $LengthBytes,
        $ColorBytes
    ) | ForEach-Object {
        $BinaryWriter.Write($_)
    }
    
    $TCPMessage.Data = ($BinaryWriter.BaseStream.ToArray())
    $BinaryWriter.BaseStream.SetLength(0)
    Send-TCPBytes @TCPMessage
}