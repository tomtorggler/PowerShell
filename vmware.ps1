function Get-Fnic {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]    
        $Name
    )
    process {
        try {
            $xcli = Get-EsxCli -VMHost $Name -ErrorAction Stop
        } catch {
            Write-Warning "Could not connect EsxCli to $Name"
            break
        }
        $output = $xcli.software.vib.list()
        $outData = @{
            'Host' = $Name;
            'Version' = $output.Where{$_.Name -like "scsi-fnic"}.Version;
            'ID' = $output.Where{$_.Name -like "scsi-fnic"}.ID;
        }
        Write-Output (New-Object -TypeName psobject -Property $OutData)
    }
}
function Get-Enic {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]    
        $Name
    )
    process {
        try {
            $xcli = Get-EsxCli -VMHost $Name -ErrorAction Stop
        } catch {
            Write-Warning "Could not connect EsxCli to $Name"
            break
        } 
        foreach ($nic in ($xcli.network.nic.list()).Name) {
            $outData = @{
                'Host' = $Name;
                'Driver'  = ($xcli.network.nic.get($nic).DriverInfo).Driver;
                'FirmwareVersion'  = ($xcli.network.nic.get($nic).DriverInfo).FirmwareVersion;
                'Version'  = ($xcli.network.nic.get($nic).DriverInfo).Version;
            }
            Write-Output (New-Object -TypeName psobject -Property $OutData)   
        }
    }
}