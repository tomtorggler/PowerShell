function Add-RsToSubVs {
    <#
    .Synopsis
       Add a Real Server to one or more sub virtual services on a KEMP load balancer.
    .DESCRIPTION
       This function calls Send-LBMessage to add a Real Server to sub virtual services.
       A filter for the virtual services nickname can be used in order to add the real server
       to multiple sub VS matching the filter. Alternatively, the function takes objects returned
       from Get-VirtualService and adds the real server to each returned VS.
    .EXAMPLE
       Add-RsToSubVs -SubVsFilter "Exchange 2013*" -RealServer 192.168.1.1 -Port 443

       This example adds RS 192.168.1.1:443 to all sub virutal services matching the name "Exchange 2013*"
    .EXAMPLE
       Get-VirtualService | Where-Object {$_.nickname -like "Exchange 2013*"} | Add-RsToSubVs -RealServer 192.168.1.1 -Port 443 -Weight 2000

       This example adds RS 192.168.1.1:443 to all virtual services returned by Get-VirtualService and the following filter.
       Please note: Get-VirtualService returns only sub virtual services, no addtional filtering is done.
    .INPUTS
       This cmdlet takes input objects from Get-VirtualService
    #>
    [CmdletBinding(SupportsShouldProcess=$true, 
                   ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName='Index')]
        [int]
        $Index,

        [Parameter(Mandatory=$true,
            ParameterSetName='NamePrefix')]
        [string]
        $SubVsFilter,
        
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

    if ($PSCmdlet.ParameterSetName -eq "Index") {        Write-Verbose "VS from Pipeline, Index $Index"
        if ($pscmdlet.ShouldProcess("VS $Index", "Add RS $RealServer`:$Port")) {
            Send-LBMessage -command addrs -ParameterValuePair @{"vs"=$Index ; "rs"=$RealServer; "rsport"=$Port; "weight"=$Weight }
        }    } else {
        Write-Verbose "Getting VS from Filter $SubVsFilter"
        $subVSGroup = Get-VirtualService | Where-Object {$_.nickname -like $SubVsFilter -and $_.mastervs -eq 0 -and (-not$_.subvs)}
        foreach ($subVs in $subVSGroup) {
            if ($pscmdlet.ShouldProcess($subVs.nickname, "Add RS $RealServer`:$Port")) {
                Send-LBMessage -command addrs -ParameterValuePair @{"vs"=$subVs.Index ; "rs"=$RealServer; "rsport"=$Port; "weight"=$Weight }
            }
        }
    }
}