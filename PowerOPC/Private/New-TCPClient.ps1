function New-TCPClient {
    [CmdletBinding()]
	Param(
		[Parameter()]
        [Int]$port=1655,
        [Parameter(Mandatory)]
        [string]$server,
        [Parameter(Mandatory)]
        [PSCredential]$Credential
	)

	$client = (New-Object System.Net.Sockets.TcpClient $server, $port)
    $stream = $client.GetStream()
	$Session = New-Object Net.Security.NegotiateStream -ArgumentList $stream

	Try {
        $Session.AuthenticateAsClient(
            $Credential.GetNetworkCredential(),
            "MYSERVICE\$Server",
            [System.Net.Security.ProtectionLevel]::EncryptAndSign,
            [System.Security.Principal.TokenImpersonationLevel]::Impersonation
        )
        $Session
    } Catch {
        Write-Warning $_.Exception.Message
    }
}