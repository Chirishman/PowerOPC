function New-OpenPixelControlSession {
    Param(
        [Parameter()]
        [Int]$port=1655,
        [Parameter(Mandatory)]
        [string]$server,
        [Parameter()]
        [PSCredential]$Credential = (Get-StoredCredential -CredName Self)
    )

    if (-not(Get-Variable -Name TCPSessions -ErrorAction SilentlyContinue)){
        $Global:OpenPixelControlSessions = [System.Collections.ArrayList]::new()
    }

    $ThisSession = New-Object -TypeName PSObject -Property [ordered]@{
        Id = $Global:OpenPixelControlSessions.Count
        Server = $server
        Session = New-TCPClient @PSBoundParameters
    }

	if ($ThisSession.Session){
		[void]$Global:OpenPixelControlSessions.Add($ThisSession)
	}
}