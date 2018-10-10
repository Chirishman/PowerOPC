function New-OpenPixelControlServerSession {
    [CmdletBinding()]
    Param(
        [int]$port = 1655
    )

    if (-not $Global:OpenPixelControlListenerSession) {
        $Global:OpenPixelControlListenerSession = [system.collections.arraylist]::new()
    }

    if (-not ($Client = $Global:OpenPixelControlListenerSession | ? {$_.Port -eq $port})) {
        Write-Verbose -Message 'Bootstrapping Client'
        $Client = Initialize-TCPListener -Id $Global:OpenPixelControlListenerSession.Count -Port $port
    }
    
    #Validate Alternate credentials
    Write-Verbose -Message 'Requesting Creds'
    Request-TCPCredential -Client ([ref]$Client)
    [void]$Global:OpenPixelControlListenerSession.Add($Client)
}