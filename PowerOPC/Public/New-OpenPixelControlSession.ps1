function New-OpenPixelControlSession {
    [CmdletBinding()]
    Param(
        [Parameter()]
        [Int]$port = 1655,
        [Parameter(Mandatory)]
        [string]$server,
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [PSCredential]$Credential = (Get-StoredCredential -CredName Self)
    )

    if (-not(Get-Variable -Name OpenPixelControlSessions -ErrorAction SilentlyContinue)) {
        $Global:OpenPixelControlSessions = [System.Collections.ArrayList]::new()
        $Id = 0
    }
    else {
        $Id = ($Global:OpenPixelControlSessions | measure -Maximum Id | select -ExpandProperty Maximum) + 1
    }

    if (-not $Name) {
        $Name = 'Session{0:000}' -f $Id
    }
    
    if (($MatchingSession = $Global:OpenPixelControlSessions | ? {$_.server -eq $server -and $_.port -eq $port})) {
        $MatchingSession.Name = $Name
        $MatchingSession.Session = New-TCPClient @PSBoundParameters
    }
    else {
        $ThisSession = New-Object -TypeName PSObject -Property ([ordered]@{
                Id      = $Id
                Name    = $Name
                Server  = $server
                Session = New-TCPClient @PSBoundParameters
            })

        if ($ThisSession.Session) {
            [void]$Global:OpenPixelControlSessions.Add($ThisSession)
        }
    }
}