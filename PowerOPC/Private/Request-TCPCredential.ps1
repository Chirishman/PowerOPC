function Request-TCPCredential {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Ref]$Client
    )
    
    $Client.Value.Client = $Client.Value.Listener.AcceptTcpClient()

    Write-Verbose -Message 'Getting Stream'
    $Client.Value.Stream = $Client.Value.Client.GetStream()
    
    Write-Verbose -Message 'Opening Negotiation Stream'
    $Client.Value.Session = New-Object Net.Security.NegotiateStream  -ArgumentList $Client.Value.Stream


    Try {
        $Client.Value.Session.AuthenticateAsServer(
            [System.Net.CredentialCache]::DefaultNetworkCredentials,
            [System.Net.Security.ProtectionLevel]::EncryptAndSign,
            [System.Security.Principal.TokenImpersonationLevel]::Impersonation
        )
        $AuthMessage = @{
            MessageData       = ("{0} authenticated as {1} via {2}" -f @($Client.Value.Client.RemoteEndPoint.Address, $Client.Value.Session.RemoteIdentity.Name, $Client.Value.Session.RemoteIdentity.AuthenticationType))
            Tags              = 'Auth'
            InformationAction = 'Continue'
        }
        Write-Information @AuthMessage
    }
    Catch {
        Write-Warning $_.Exception.Message
    }
}