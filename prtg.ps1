


function Stop-PrtgProbe {
    <#
    .SYNOPSIS
        Stop a PRTG probe.
    .DESCRIPTION
        This function uses the API to stop a PRTG probe (eg. before patching a system)
    .EXAMPLE
        PS C:\> Stop-PrtgProbe -UserName <user> -Password <pass> -ProbeId 10659 -Message "Pause Test" -Duration 60 
        This example stops probe id 10659 for 60 seconds
    .INPUTS
        None.
    .OUTPUTS
        None.
    .NOTES
        The api sucks.
    #>
    [CmdletBinding()]
    param (
        $ComputerName = "prtg01.uclab.eu",
        $UserName,
        $Password,
        $ProbeId,
        $Message = "Paused by script",
        $Duration = 300
    )
    $Message = [uri]::EscapeUriString($Message)
    $uri  = "https://$ComputerName/api/pauseobjectfor.htm?id=$ProbeId&pausemsg=$Message&duration=$Duration&username=$Username&password=$password"
    $null = Invoke-RestMethod -Uri $uri
}

function Resume-PrtgProbe {
    <#
    .SYNOPSIS
        Resume a PRTG probe.
    .DESCRIPTION
        This function uses the API to resume a previously stopped PRTG probe (eg. after patching a system)
    .EXAMPLE
        PS C:\> Resume-PrtgProbe -UserName <user> -Password <pass> -ProbeId 10659 
        This example resumes probe id 10659 
    .INPUTS
        None.
    .OUTPUTS
        None.
    .NOTES
        The api sucks. 
    #>
    [CmdletBinding()]
    param (
        $ComputerName = "prtg01.uclab.eu",
        $UserName,
        $Password,
        $ProbeId
    )
    $uri  = "https://$ComputerName/api/pause.htm?id=$ProbeId&action=1&username=$Username&password=$password"
    $null = Invoke-RestMethod -Uri $uri
}
