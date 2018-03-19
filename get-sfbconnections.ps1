
<#
    This is a stripped down version of https://www.ucunleashed.com/269 Get-CsConnections.ps1
#>
function Get-SFBConnections {
    param([string]$PoolFqdn)
    begin {
        function Get-Data {
	        [CmdletBinding()]
	        param ([string]$Server)

            #Define SQL Connection String and command
	        [string] $connstring = "server=$server\rtclocal;database=rtcdyn;trusted_connection=true;"
	        [object] $command = New-Object System.Data.SqlClient.SqlCommand

	        # SQL query for Lync Server 2013
	        $command.CommandText = "Select (cast (RE.ClientApp as varchar (100))) as ClientVersion, R.UserAtHost as UserName, RA.Fqdn `
	        From rtcdyn.dbo.RegistrarEndpoint RE `
	        Inner Join rtcdyn.dbo.Endpoint EP on RE.EndpointId = EP.EndpointId `
	        Inner Join rtc.dbo.Resource R on R.ResourceId = RE.OwnerId `
	        Inner Join rtcdyn.dbo.Registrar RA on EP.RegistrarId = RA.RegistrarId `
	        Order By ClientVersion, UserName"

	        [object] $connection = New-Object System.Data.SqlClient.SqlConnection
	        $connection.ConnectionString = $connstring
            try {
                $connection.Open()
            }
            catch {
                Write-Warning "Could not connect to $server"
                return
            }

	        $command.Connection = $connection

	        [object] $sqladapter = New-Object System.Data.SqlClient.SqlDataAdapter
	        $sqladapter.SelectCommand = $command

	        [object] $results = New-Object System.Data.Dataset
	        $recordcount = $sqladapter.Fill($results)
            $connection.Close()
	        return $Results.Tables[0]
        }
    }
    process {
        $feServers = Get-CsComputer -Pool $PoolFqdn -ErrorAction Stop | Sort-Object identity
        $global:Records = @()
        foreach ($fe in $feServers) {
            Write-Verbose "Getting info for $($fe.identity)"
            $data = Get-Data -Server $fe.identity
            if ($data) {
                $global:Records += $data
            }
        }
        $global:Records
        Write-Host -ForegroundColor Yellow "Result available in `$Records"
    }
}
