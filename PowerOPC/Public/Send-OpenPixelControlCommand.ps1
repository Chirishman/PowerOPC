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
                'Id' { $Global:OpenPixelControlSessions | ? {$_.Id -eq $SessionId} | Select -ExpandProperty Session }
                'SessionName' { $Global:OpenPixelControlSessions | ? {$_.Name -eq $Name}  | Select -ExpandProperty Session }
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
    [Byte[]]$ColorBytes = $Color | % {
        [byte[]]($_.R, $_.G, $_.B)
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
    ) | % {
        $TCPMessage.Data = $_
        Send-TCPBytes @TCPMessage
    }
}