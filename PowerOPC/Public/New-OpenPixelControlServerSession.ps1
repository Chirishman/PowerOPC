function New-OpenPixelControlServerSession {
    Param(
        [int]$port=1655
    )

	if (-not $Global:OpenPixelControlListenerSession) {
		$Global:OpenPixelControlListenerSession = [system.collections.arraylist]::new()
	}

	$Session = Initialize-TCPListener -Id $Global:OpenPixelControlListenerSession.Count -Port $port

    #Validate Alternate credentials
    Try {
        $Session.Session.AuthenticateAsServer(
            [System.Net.CredentialCache]::DefaultNetworkCredentials,
            [System.Net.Security.ProtectionLevel]::EncryptAndSign,
            [System.Security.Principal.TokenImpersonationLevel]::Impersonation
        )
        Write-host "$($client.client.RemoteEndPoint.Address) authenticated as $($Session.Session.RemoteIdentity.Name) via $($Session.Session.RemoteIdentity.AuthenticationType)" -Foreground Green -Background Black
		$Global:OpenPixelControlListenerSession.Add($Session)
    } Catch {
        Write-Warning $_.Exception.Message
    }
}