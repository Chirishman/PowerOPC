# PowerOPC

PowerShell implementation of [Open Pixel Control](http://openpixelcontrol.org) server and client

This can be used with any lighting endpoint as most of that logic is offloaded to scripts external to this module.

## Usage

### Blink(1) Server Example

This example can be used to listen for remote color commands and apply them to a local Blink(1)mk2 device.

The Channel parameter is intended for use in controlling parallel devices of the same type, for instance the 8 parallel LED strips supported by the OctoWS2811 Teensy library or the individual outputs of a FadeCandy board (the original implementation of Open Pixel Control)

```PowerShell
Import-Module PowerBlink
Import-Module PowerOPC

Initialize-Blink1Devices

While ($True) {
    try {
        $ReceivedCommand = Start-OpenPixelControlListener -port 1655
        if ($ReceivedCommand.Channel -eq 1) {
            if ($ReceivedCommand.Command -eq 0) {
                1..($ReceivedCommand.ColorArray.Count) | % {
                    Set-Blink1Color -DeviceNumber ($ReceivedCommand.Channel - 1) -Color $ReceivedCommand.ColorArray[($_ - 1)] -Address $_ -ErrorAction SilentlyContinue
                }
            }
        }
    } catch {
        Write-Information -MessageData 'Bad Data, reattempting'
    }
}
```

### Fit-StatUSB Server Example

This example can be used to listen for remote color commands and apply them to a local Fit-StatUSB device

```PowerShell
Import-Module PowerOPC
Import-Module StatUSB

Connect-StatUSBPort
$Ports = $Global:SerialConnections | ?{$_.port.IsOpen}

$UUID = $Global:SerialConnections.UUID

While ($True) {
    try{
        $ReceivedCommand = Start-OpenPixelControlListener -port 1655
        if ($ReceivedCommand.Channel -eq 1) {
            if ($ReceivedCommand.Command -eq 0) {
                Send-StatUSBCommand -Command (New-StatUSBCommand -Color $ReceivedCommand.ColorArray) -TargetID $UUID
            }
        }
    } catch{
        Write-Information -MessageData 'Bad Data, reattempting'
    }
}
```

### Control command example for dual LED devices such as the Blink(1)mk2

```PowerShell
New-OpenPixelControlSession -server Chiri-Dev -Credential (Get-Credential) -port 1655 -Name Blink

$WaitTime = 800
while ($true) {
    Send-OpenPixelControlCommand -Channel 1 -Command 8BitColor -Color @('Yellow','Blue') -Name Blink
    Start-Sleep -Milliseconds $WaitTime
    Send-OpenPixelControlCommand -Channel 1 -Command 8BitColor -Color @('Green','Red') -Name Blink
    Start-Sleep -Milliseconds $WaitTime
    Send-OpenPixelControlCommand -Channel 1 -Command 8BitColor -Color @('Blue','Yellow') -Name Blink
    Start-Sleep -Milliseconds $WaitTime
}
```

### Example Use Case - Presence Notifier

This example is intended to be run on a central automation server and reaches out to the notifier light on your desk. It uses PSRemoting to attempt to discern the presence or absence of two users at their computers and toggle respective status lights.

Personally I uses this to figure out whether or not I need to answer the main helpdesk line (if the two Tier 1 guys are not at the desk) since I can't see them from my desk.

```PowerShell
function Get-BulkPresenceColor {
    [CmdletBinding()]
    Param(
        [string[]]$Computer
    )

    $Computer = $Computer | Sort-Object

    $UserPresenceResults = (Invoke-Command -ComputerName $Computer -Credential (Get-StoredCredential -CredName Admin) -ScriptBlock {

        New-Object PSObject -Property @{
            UserPresent=$(
                if ((gwmi -Class win32_computersystem | select -ExpandProperty username) -and (-not (get-process logonui -ea silentlycontinue))) {
                        $true
                } else {
                        $false
                }
            )
        }
    } -ErrorAction SilentlyContinue) | Sort-Object -Property PSComputerName

    $ColorLookup = @{
        $True = [System.Drawing.Color]::Green
        $False = [System.Drawing.Color]::Red
    }

    Write-Verbose -Message (-join($UserPresenceResults | out-string))

    $Computer | %{
        $ThisComputer = $_
        $ThisResult = $UserPresenceResults | ?{$_.PSComputerName -eq $ThisComputer}
        $ColorLookup[$(
            if ($ThisResult) {
                $ThisResult.UserPresent
            } else {
                $False
            }
        )]
    }
}

Function Show-HelpdeskPresence {
    [CmdletBinding()]
    Param(
        [switch]$RunOnce
    )

    $RunState = (-not $RunOnce)
    [System.Drawing.Color[]]$LastColorResults = [System.Drawing.Color[]]::new(2)

    Do {

        [System.Drawing.Color[]]$ColorResults = (Get-BulkPresenceColor -Computer @('TargetComputer1','TargetComputer2'))

        $ResultPattern = -join([byte[]]((0..($ColorResults.Count - 1) | %{$LastColorResults[$_] -eq $ColorResults[$_]})))

        if ($ResultPattern -ne '11') {
            Write-Verbose -Message 'Change Found - Sending Command'
            Send-OpenPixelControlCommand -Channel 1 -Command 8BitColor -Color $ColorResults -Name Blink
            $ColorResults.CopyTo($LastColorResults,0)
        } else {
            Write-Verbose -Message 'No Change Found'
        }

        Write-Verbose -Message ('Sleeping' * $RunState)
        Start-Sleep -Seconds (30 * $RunState)
    } While ($RunState)
}

Show-HelpdeskPresence
```