
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



function Set-DhcpProvServ {
    <#
    .SYNOPSIS
        Set DHCP Option 160 (provisioning server) for a scope on one or more DHCP servers.
    .DESCRIPTION
        This function can be used to set the Provisioning Server DHCP Option (160)
    .EXAMPLE
        PS C:\> Set-DhcpProvServ -ComputerName "dhcp01.example.com" -ScopeId "192.168.1.0" -Uri "http://192.168.1.10/firmwarefiles;ipp/tenant/uclab_de"
        
        This example sets the provisioning server option for scope 192.168.1.0 on server dhcp01.
    .EXAMPLE
        PS C:\> $c = New-CimSession -ComputerName "dhcp01.example.com","dhcp02.example.com"
        PS C:\> Get-DhcpServerv4Scope -ScopeId 192.168.1.0,192.168.2.0 -CimSession $c | Set-DhcpProvServ -Uri "http://192.168.1.10/firmwarefiles;ipp/tenant/uclab_de" -PassThru

        OptionId   Name            Type       Value                VendorClass     UserClass       PolicyName     
        --------   ----            ----       -----                -----------     ---------       ----------     
        160        Provisioning... String     {http://192.168.1...                                                
        160        Provisioning... String     {http://192.168.1...                                                
        160        Provisioning... String     {http://192.168.1...                                                
        160        Provisioning... String     {http://192.168.1...                                                

        In this example, we create a new CIM session to two remote DHCP Servers and then we use Get-DhcpServerv4Scope to retrieve two scopes from each Server. 
        We use the scopes as input for the Set-DhcpProvServ function and set the Option 160 to the same URI on all scopes. 

    .INPUTS
        [Microsoft.Management.Infrastructure.CimInstance]
    .OUTPUTS
        None.
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding(
        SupportsShouldProcess=$true,
        DefaultParameterSetName="ByComputerName"    
    )]
    param(
        [Parameter(Mandatory,ParameterSetName="ByComputerName")]
        [string[]]
        $ComputerName,
        [Parameter(ParameterSetName="ByObject",ValueFromPipeline=$true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $InputObject,
        [Parameter()]
        [System.Net.IPAddress[]]
        $ScopeId,
        [Parameter(Mandatory)]
        [string]
        $Uri,
        [Parameter()]
        [switch]
        $PassThru
    )
    process {
        if($InputObject) {
            Write-Verbose "Information by input object"
            $ComputerName = $InputObject.PSComputerName
            $ScopeId = $InputObject.ScopeId
        }
        foreach ($dhcpSrv in $ComputerName) {
            Write-Verbose "DHCP Server is $dhcpSrv"
            foreach ($scope in $ScopeId) {
                Write-Verbose "ScopeId is $scope"
                if ($pscmdlet.ShouldProcess("$dhcpSrv\$scope", "Set Option 160 to $Uri")) {
                    Set-DhcpServerv4OptionValue -ScopeId $scope -OptionId 160 -Value $Uri -ComputerName $dhcpSrv -PassThru:$PassThru
                }
            }
        } 
    }
}



function Get-DhcpProvServ {
        <#
    .SYNOPSIS
        Get DHCP Option 160 (provisioning server) for a scope from one or more DHCP servers.
    .DESCRIPTION
        This function can be used to get the Provisioning Server DHCP Option (160).
    .EXAMPLE
        PS C:\> Get-DhcpProvServ -ComputerName "dhcp01.example.com" -ScopeId "192.168.1.0"
        
        This example gets the provisioning server option for scope 192.168.1.0 from server dhcp01.
    .EXAMPLE
        PS C:\> $c = New-CimSession -ComputerName "dhcp01.example.com","dhcp02.example.com"
        PS C:\> Get-DhcpServerv4Scope -ScopeId 192.168.1.0,192.168.2.0 -CimSession $c | Get-DhcpProvServ

        In this example, we create a new CIM session to two remote DHCP Servers and then we use Get-DhcpServerv4Scope to retrieve two scopes from each Server. 
        We use the scopes as input for the Get-DhcpProvServ function and get configured value for each scope. 

    .INPUTS
        [Microsoft.Management.Infrastructure.CimInstance]
    .OUTPUTS
        [psobject]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding(DefaultParameterSetName="ByComputerName")]
    param(
        [Parameter(ParameterSetName="ByComputerName")]
        [string[]]
        $ComputerName,
        [Parameter(ParameterSetName="ByObject",ValueFromPipeline=$true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $InputObject,
        [Parameter()]
        [System.Net.IPAddress[]]
        $ScopeId,
        [Parameter()]
        [int]
        $optionId = 160
    )
    process {
        if($InputObject) {
            $ComputerName = $InputObject.PSComputerName
            $ScopeId = $InputObject.ScopeId
        }
        foreach ($s in $ComputerName) {
            Write-Verbose "Server is $s"
            foreach($scope in $ScopeId){
                Write-Verbose "Scope is $scope"
                $o = Get-DhcpServerv4OptionValue -ScopeId $scope -OptionId $optionId -ComputerName $s -ErrorAction SilentlyContinue
                New-Object -TypeName psobject -Property ([ordered]@{
                    DhcpServer = $s
                    Scopde = $scope
                    ProvisioningServer = $o.Value
                })
            }
        }
    }    
}
