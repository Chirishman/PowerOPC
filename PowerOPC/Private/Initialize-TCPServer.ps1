function Initialize-TCPListener {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [int]$Id,
        [Parameter()]
        [int]$port = 1655
    )

    $endpoint = new-object System.Net.IPEndPoint ([system.net.ipaddress]::any, $port)
    $listener = new-object System.Net.Sockets.TcpListener $endpoint
    $listener.start()
    
    New-Object -TypeName PSObject -Property ([Ordered]@{
            Id       = $Id
            Port     = $port
            Endpoint = $Endpoint
            Listener = $Listener
            Client   = $null
            Stream   = $null
            Session  = $null
        })
}