
# import cdr from: .\a.b.c.d\CDR\*.log
# create temp files in: .\a.b.c.d\temp\*.txt
# move imported files to: .\a.b.c.d\spluked\*.log



function Import-CdrSplunk {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Folder containing cdr syslogs 
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $Path,

        # Filter
        [Parameter()]
        [string]
        $Filter = "*.log"
    )
    # load functions 
    . C:\users\thomas.torggler\Git\PowerShell\AudioCodesCdr.ps1
    . C:\Users\thomas.torggler\Git\PowerShell\Send-SplunkEvent.ps1

    # get files     
    $SyslogFiles = Get-ChildItem -Path $Path\*\CDR\$Filter 
    $UniqueHosts = $SyslogFiles | Get-HostFromPath | Select-Object -Unique
    foreach($ip in $UniqueHosts){
        Write-Verbose "Current host is $IP"
        $perHostPath = Join-Path -Path $Path -ChildPath $ip
        $FilesToImport = Get-ChildItem -Path $perHostPath\CDR\$Filter | Sort-Object -Property LastWriteTime | Select-Object -Last 1

        foreach($f in $FilesToImport) {
            if ($pscmdlet.ShouldProcess($f, "Import")) {
                $null = New-Item -Path $perHostPath -Name temp -Type Directory -ErrorAction SilentlyContinue
    
                $f | Split-Cdr -OutputFolder $perHostPath\temp 
                $SbcTitle = Get-CdrTitle -Type SBC -Path $SyslogFiles[0].FullName
                $MediaTitle = Get-CdrTitle -Type MEDIA -Path $SyslogFiles[0].FullName

                Write-Verbose "SBC Title: $($SbcTitle -join ', ')"
                Write-Verbose "Media Title: $($MediaTitle -join ', ')"

                $SbcObjects = Get-ChildItem -Path $Path\*\temp\sbc.txt | Import-Cdr -Header $SbcTitle
                $MediaObjects = Get-ChildItem -Path $Path\*\temp\media.txt | Import-Cdr -Header $MediaTitle

                $SbcObjects | % {Send-SplunkEvent -HostName $ip -DateTime $_.TimeStamp -InputObject $_  } 
                $MediaObjects | % {Send-SplunkEvent -HostName $ip -DateTime $_.TimeStamp -InputObject $_  }
                    
            }
        }
    }    
}
