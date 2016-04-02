function Get-DiskSpaceReport {
    <#
    .Synopsis
       Get information about free disk space from remote computers and create a HTML report.
    .DESCRIPTION
       This function uses WMI to query one or more remote computers for disk space information. A HTML report will be
       created for each Computer that could be reached. The -ReportPath parameter specifies a folder where the reports will
       be generated. The -ErrorLog parameter can be used to wirte unreachable computers to a separate file.
    .INPUTS
       [String[]]
    .OUTPUTS
       [none]
    .NOTES
       This function was created for the Scripting Games 2013.
       Author: thomas torggler; @torggler
       Date: 2013-05-12
    .EXAMPLE
       Get-DiskSpaceReport -ComputerName srv1 -ReportPath C:\temp

       This example creates a file srv1.html in c:\temp. The file contains information about srv1's fixed disks.
    .EXAMPLE
       Get-DiskSpaceReport -ComputerName (Get-Content C:\temp\servers.txt) -ReportPath C:\temp -ErrorLog C:\temp\error.txt

       This example assumes you have a file with server names, one per line, located at C:\temp\servers.txt. This example will create a file for every Server within c:\temp. It will also log unreachable Servers to C:\temp\error.txt.
    .EXAMPLE
       Get-DiskSpaceReport -ComputerName srv1 -ReportPath C:\temp -Credential (Get-Credential) -PassThru

       This example prompts for credentials before connecting to srv1. It creates a report at C:\temp\ and writes the resulting objects to the pipeline, too.  
    #>

    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Specify one or more Computername(s) using a comma to separate values. The function queries those Computername(s) for information. This parameter accepts pipline input.
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        # Speficy a folder where HTML reports will be generated.
        [Parameter(Mandatory=$true,
                    Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]
        $ReportPath,
        
        # Specify a file to log unreachable computers.
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $ErrorLog,
        
        # Specify credentials to connect to the servers. 
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Output objects to the pipeline
        [Switch]
        $PassThru
    )

    Begin
    {   
        ### If Credential parameter is used, add it to the Get-WmiObject cmdlet
        if ($Credential) {
            $wmiParam = @{'Credential'=$Credential; 'ErrorAction'="Stop"}
        } else {
            $wmiParam = @{'ErrorAction'="Stop"}
        }

        ### check if ReportPath exists and try to create folder if it doesn't
        try {
            if (-not(Test-Path $ReportPath)) {
                Write-Verbose "Report Path doesn't exist, trying to create $ReportPath"
                New-Item -Path $ReportPath -ItemType Directory -ErrorAction Stop -ErrorVariable CreateFolderError | Out-Null
            }
            Write-Verbose "Report Path exists" 
        } catch {
            Write-Warning -Message "Could not create folder: $($CreateFolderError.ErrorRecord)"
            break
        }

        ### if ErrorLog is used, delete existing files and try to create a new one
        try {
            if ($ErrorLog) {
                Write-Verbose "ErrorLog will be created at $ErrorLog. If the file already exists, delete it"
                Remove-Item -Path $ErrorLog -ErrorAction SilentlyContinue
                New-Item $ErrorLog -ItemType File -ErrorAction Stop -ErrorVariable CreateErrorLogError | Out-Null
            }
        } catch {
            Write-Warning -Message "Could not create file: $($CreateErrorLogError.ErrorRecord) Script continues without ErrorLogging"
            # Delete Variable, so Out-File does not produce errors later on
            Remove-Variable -Name ErrorLog
        }

    } # End Begin

    Process
    {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Trying to connect to $Computer using WMI"
            $Continue = $true

            try {
                Write-Verbose "Querying WMI on $Computer"
                $LogicalDisk = Get-WmiObject @wmiParam -ComputerName $Computer -Class Win32_LogicalDisk -Filter “DriveType=3" -Property SystemName,DeviceID,FreeSpace,Size
            } catch {
                Write-Warning "Failed to connect to $Computer"
                if ($ErrorLog) {
                    Write-Warning "Writing $Computer to $ErrorLog"
                    $Computer | Out-File -FilePath $ErrorLog -Append
                }
                $Continue = $false
            }
            
            if ($Continue) {
                
                # Create HTML code for heading
                $htmlHead = "
                    <html>
                    <head>
                    <title>Disk Free Space Report</title>
                    </head>
                    <body>
                    <p>
                    <h2>Local Fixed Disk Report for $($LogicalDisk.SystemName | select -Unique)</h2>
                    <p>
                    <table>
                    <tr>
                    <th>Drive</th>
                    <th>Size(GB)</th>
                    <th>FreeSpace(MB)</th>
                    </tr>
                "
                # initialize HTML table 
                $htmlTable = $null
                
                ### enumerate disks, create a row in the table for each disk and create an array for optional output
                foreach ($Disk in $LogicalDisk) {
                
                    # create dictionary to work with
                    $Data = [ordered]@{
                        'ComputerName'=$Disk.SystemName;
                        'DeviceID'=$Disk.DeviceID;
                        'Size'=$Disk.Size;
                        'FreeSpace'=$Disk.FreeSpace;                
                    }

                    if ($PassThru) {
                        # Write psobject to the pipeline, I don't convert the values here
                        Write-Output (New-Object -TypeName PSObject -Property $Data)
                    }
                
                    ### Generate HTML Table
                    $htmlTable += foreach ($item in $Data) { 
                        "<tr><td>$($item.DeviceID)</td>
                        <td>$(“{0:N2}” -f($item.Size/1GB))</td>
                        <td>$(“{0:N2}” -f($item.FreeSpace/1MB))</td></tr>"
                    }
                    
                } # end foreach disk in logicaldisk

                ### create end of the HTML file, includes horizontal rule and current date
                $htmlTail ="
                    </table>
                    </body>
                    <hr/>
                    <a>$(Get-Date)</a>
                    </html>
                "

                ### combining parts to report
                $htmlReport = $htmlHead + $htmlTable + $htmlTail
                
                ### try to write html report to a file
                try {
                    $htmlReport | Out-File -FilePath $ReportPath\$($LogicalDisk.SystemName | select -Unique)".html" -ErrorAction Stop -ErrorVariable OutFileError
                } catch {
                    Write-Warning "Could not create logfile: $($OutFileError.ErrorRecord)"
                }

            } # End if $Continue
        } # End ForEach $ComputerName
	} # End Process	

    End
    {
    } # End End :)
} # End Get-DiskSpaceReport