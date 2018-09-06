
function Get-IPPCfg {
    <#
    .SYNOPSIS
        Get phone cfg from AudioCodes IP Phone Manager (Express).
    .DESCRIPTION
        This function uses Invoke-WebRequest to retreive configuration information from an AudioCodes IP Phone Manager.
    .EXAMPLE
        PS C:\> Get-IPPCfg -ComputerName acipp01.uclab.eu -Phone 450HD -Tenant uclab_de
        This example gets the config template file for 450HD phones in the uclab_de tenant.
    .INPUTS
        None.
    .OUTPUTS
        [psobject]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding()]
    param(
        # FQDN of the IP Phone Manager 
        [Parameter(Mandatory)]
        [string]$ComputerName,
        # IP Phone Type
        [Parameter(Mandatory)]
        [ValidateSet("450HD","445HD","440HD","420HD")]
        [string]$Phone,
        # MAC Address of an IP Phone to get a specific config file
        [Parameter()]
        [string]$MacAddress = "00065BBC7AC7",
        # Tenant Name as configured on IP Phone Manager
        [Parameter()]
        [string]$Tenant = "Default"
    )
    $uri = "http://{0}/ipp/tenant/{1}/{2}.cfg" -f $ComputerName,$Tenant,$MacAddress
    $ua = "AUDC-IPPhone-{0}_UC_0.0.0.0/0" -f $Phone
    $result = Invoke-WebRequest -Uri $uri -UserAgent $ua
    New-Object -TypeName psobject -Property ([ordered]@{
        TemplateName = $result.headers["X-Template-Name"]
        Content = ConvertFrom-ByteArray($result.content)
    })

}
function ConvertFrom-ByteArray($i) {
    $enc = [System.Text.Encoding]::ASCII
    $enc.GetString($i)
}
