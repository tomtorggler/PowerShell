
function Add-RsToSubVs {
    [CmdletBinding(SupportsShouldProcess=$true, 
                    ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $SubVsPrefix,
        
        [Parameter(Mandatory=$true)]
        [ipaddress]
        $RealServer,
        
        [Parameter(Mandatory=$true)]
        [ValidateRange(1,65535)]
        [int]
        $Port,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,65535)]
        [int]
        $Weight=1000
    )

    $subVSGroup = Get-VirtualService | Where-Object {$_.nickname -like $SubVsPrefix -and $_.mastervs -eq 0 -and (-not$_.subvs)}

    foreach ($subVs in $subVSGroup) {
        if ($pscmdlet.ShouldProcess($subVs.nickname, "Add RS $RealServer`:$Port")) {
            Send-LBMessage -command addrs -ParameterValuePair @{"vs"=$subVs.Index ; "rs"=$RealServer; "rsport"=$Port; "weight"=$Weight }
        }
    }
}



