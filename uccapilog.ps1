
# extracing some useful bits from the uccapilog
function Get-DialPlan {
    [CmdletBinding()]
    param(
        $Path = "$env:USERPROFILE\AppData\Local\Microsoft\Office\16.0\Lync\Tracing\",
        [switch]$all
    )
    $logs = Get-ChildItem -Path $Path -Filter "*.uccapilog"
    $DPs = Select-String -Pattern "LocationProfileDescription" -Path $logs 

    if($all) {
        [system.io.fileinfo[]]$paths = $DPs | Select-Object -Property path -Unique
    }

    foreach($dp in $DPs) {
        new-object -type psobject -Property @{
            FileName = $dp.FileName
            DialPlan = ([xml]$dp.Line).LocationProfileDescription.Name
            Rules = ([xml]$dp.Line).LocationProfileDescription.Rule
        }
    }
}

function Get-IceWarn {
    [CmdletBinding()]
    param(
        $Path = "$env:USERPROFILE\AppData\Local\Microsoft\Office\16.0\Lync\Tracing\",
        $Count = 1
    )
    $logs = Get-ChildItem -Path $Path -Filter "*.uccapilog"
    $l = Select-String -Pattern "ICEwarn=0x\d*" -Path $logs | Select-Object -Last $Count | Select-Object -ExpandProperty Line
    $l | ForEach-Object {New-Object -TypeName psobject -Property @{
            ICEWarn = [regex]::match($_,"ICEWarn=(0x\d*),").Groups[1].Value
            ICEWarnEx = [regex]::match($_,"ICEWarnEx=(0x\d*),").Groups[1].Value
            LocalMR = [regex]::match($_,"LocalMR=([0-9]+(?:\.[0-9]+){3}(:[0-9]+)?)").Groups[1].Value
            RemoteMR = [regex]::match($_,"RemoteMR=([0-9]+(?:\.[0-9]+){3}(:[0-9]+)?)").Groups[1].Value
        }
    }
}
