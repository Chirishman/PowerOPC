function Initialize-TCPListener {
    Param(
		[Parameter(Mandatory)]
		[int]$Id,
		[Parameter()]
        [int]$port=1655
    )

    $endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
    $listener = new-object System.Net.Sockets.TcpListener $endpoint
    $listener.start()
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()

	New-Object -TypeName PSObject -Property ([Ordered]@{
		Id = $Id
		Port = $port
		Client = $client.client.RemoteEndPoint.Address
		Session = New-Object net.security.NegotiateStream -ArgumentList $stream
	})
}