function Initialize-TCPListener {
    Param(
        $port=1655
    )

    $endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
    $listener = new-object System.Net.Sockets.TcpListener $endpoint
    $listener.start()
    $client = $listener.AcceptTcpClient()

    $stream = $client.GetStream()
    $NegotiateStream =  New-Object net.security.NegotiateStream -ArgumentList $stream
    #Validate Alternate credentials
    Try {
        $NegotiateStream.AuthenticateAsServer(
            [System.Net.CredentialCache]::DefaultNetworkCredentials,
            [System.Net.Security.ProtectionLevel]::EncryptAndSign,
            [System.Security.Principal.TokenImpersonationLevel]::Impersonation
        )
        Write-host "$($client.client.RemoteEndPoint.Address) authenticated as $($NegotiateStream.RemoteIdentity.Name) via $($NegotiateStream.RemoteIdentity.AuthenticationType)" -Foreground Green -Background Black
    } Catch {
        Write-Warning $_.Exception.Message
    }
}