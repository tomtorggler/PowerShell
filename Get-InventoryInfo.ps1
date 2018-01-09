function Get-InventoryInfo {
    <#
    .Synopsis
       Get inventory information from remote computers.
    .DESCRIPTION
       This function was created for the Scripting Games 2013.
       This function uses WMI to query one or more remote computers for inventory information. Including OS version, physical memory (in MB) and CPU. 
       The function will always output objects to the pipline, using the -Report parameter an additional HTML report can be created. Using the
       -Credential parameter, credentials can be supplied to connect to the remote computers. To log unreachable ComputerNames to a file, use -ErrorLog.
    .INPUTS
       [String[]]
    .OUTPUTS
       [PSObject[]]
    .NOTES
       Author: thomas torggler; @torggler
       Date: 2013-05-06
    .EXAMPLE
       Get-InventoryInfo -ComputerName srv1

       This example shows inventory information about server: srv1
    .EXAMPLE
       Get-InventoryInfo -ComputerName (Get-Content C:\temp\servers.txt) -ErrorLog C:\temp\error.txt

       This example assumes you have a file with server names, one per line, located at C:\temp\servers.txt. This example will show inventory information about all accessible servers and log inaccessible ones to C:\temp\error.txt.
    .EXAMPLE
       Get-InventoryInfo -ComputerName srv1 -Report C:\temp\Report.html -Credential (Get-Credential)

       This example prompts for credentials before connecting to srv1. It creates and displays a simple HTML report at C:\temp\Report.hmtl, too.  
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

        # Specify a file to log unreachable computers.
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $ErrorLog,

        # Speficy a file for a simple HTML report that will be generated. The file will be opened once the report has been generated.
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Report,

        # Specify credentials to connect to the servers. 
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    Begin
    {
        # If ErrorLog has been used, delete existing files

        if ($ErrorLog) {
            Write-Verbose "ErrorLog will be created at $ErrorLog. If the file already exists, delete it"
            Remove-Item -Path $ErrorLog -ErrorAction SilentlyContinue
        } 
        
        # If Report has been used, delete existing files

        if ($Report) {
            Write-Verbose "Report will be created at $Report. If the file already exists, delete it"
            Remove-Item -Path $Report -ErrorAction SilentlyContinue
        }

        # If Credential parameter is used, add it to the Get-WmiObject cmdlet

        if ($Credential) {
            $wmiParam = @{'Credential'=$Credential}
        } else {
            $wmiParam = @{}
        }
    } # End Begin

    Process
    {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Trying to connect to $Computer using WMI"
            $Continue = $true

            try {
                Write-Verbose "Querying WMI on $Computer"
                $OperatingSystem = Get-WmiObject @wmiParam -ComputerName $Computer -Class Win32_OperatingSystem -ErrorAction Stop
            } catch {
                Write-Warning "Failed to connect to $Computer"
                if ($ErrorLog) {
                    Write-Warning "Writing $Computer to $ErrorLog"
                    $Computer | Out-File -FilePath $ErrorLog -Append
                }
                $Continue = $false
            }
            
            if ($Continue) {
                
                ### Query WMI for information

                $PhysicalMemory = Get-WmiObject @wmiParam -ComputerName $Computer -Class Win32_PhysicalMemory
                $Processor = Get-WmiObject @wmiParam -ComputerName $Computer -Class Win32_Processor
                
                ### Calculate Physical Memory
                # initialize TotalPhysicalMemory to 0

                $TotalPhysicalMemory = 0
                
                if ($PhysicalMemory -is [System.Array]) {
                    Write-Verbose "$Computer has $($PhysicalMemory.Count) physical memory banks installed"
                    foreach ($Bank in $PhysicalMemory) {
                        $TotalPhysicalMemory += $Bank.Capacity / 1MB 
                    }
                } else {
                    Write-Verbose "$Computer has 1 physical memory bank installed"
                    $TotalPhysicalMemory = $PhysicalMemory.Capacity / 1MB
                }

                ### Calculate number of sockets
                # initialize Sockets to 0

                $Sockets = 0

                if ($Processor -is [System.Array]) {
                    Write-Verbose "$Computer has $($Processor.Count) CPUs installed"
                    $Sockets = $($Processor.Count)
                } else {
                    Write-Verbose "$Computer has only 1 CPU installed"
                    $Sockets = 1
                }

                # As the numberOfCores property is not available pre Windows Vista/2008, only use that property if the OS supports it: http://msdn.microsoft.com/en-us/library/windows/desktop/aa394373(v=vs.85).aspx
                # initialize Cores to 0
                
                $Cores = 0 

                if ([int]$OperatingSystem.BuildNumber -gt 6000) {
                    Write-Verbose "$Computer is running $($OperatingSystem.Caption) - getting number of cores"
                    if ($Processor -is [System.Array]) {
                        foreach ($CPU in $Processor) {
                            $Cores += $CPU.numberOfCores
                        }
                    } else {
                        $Cores = $Processor.numberOfCores
                    }   
                } else {
                    Write-Verbose "$Computer is running $($OperatingSystem.Caption) - can't get number of cores"
                    $Cores = "n/a"
                }

                ### Create output object

                $Data = [Ordered]@{
                    'ComputerName'=$OperatingSystem.CSName;
                    'OSName' = $OperatingSystem.Caption;
                    'OSBuild' = $OperatingSystem.BuildNumber;
                    'ServicePack' = $OperatingSystem.ServicePackMajorVersion;
                    'Sockets' = $Sockets;
                    'Cores' = $Cores;
                    'ProcessorArchitecture' = $Processor.AddressWidth;
                    'PhysicalMemory'= $TotalPhysicalMemory
                }
                
                # Write psobject to the pipeline
                
                Write-Output (New-Object -TypeName PSObject -Property $Data)

                ### Generate simple HTML Report

                if ($Report) {
                    # collect Data for reporting purposes
                                       
                    $ReportData = @()
                    $ReportData += $Data

                    # Create HTML header and Table headers
                    $htmlHead = "
                        <html>
                        <head>
                        <title>Server Inventory Report</title>
                        </head><body>
                        <p>
                        <h1>Server Inventory Report</h1>
                        <p>
                        <p>
                        <table>
                        <tr>
                        <th>Computer Name</th>
                        <th>Operating System Name</th>
                        <th>Operating System Build Number</th>
                        <th>Service Pack Version</th>
                        <th>CPU Sockets</th>
                        <th>CPU Cores</th>
                        <th>Processor Architecture</th>
                        <th>Total Physical Memory (MB)</th>
                        </tr>
                    "
                    # Create a new row in the table foreach dataset 
                    $htmlTable += foreach ($ReportDataSet in $ReportData) {
                        "<tr><td>$($ReportData.ComputerName)</td><td>$($ReportData.OSName)</td><td>$($ReportData.OSBuild)</td><td>$($ReportData.ServicePack)</td><td>$($ReportData.Sockets)</td><td>$($ReportData.Cores)</td><td>$($ReportData.ProcessorArchitecture)</td><td>$($ReportData.PhysicalMemory)</td></tr>"
                    }

                    # Close HTML
                    $htmlTail = "
                        </table>
                        </body>
                        <p><p>---<p>
                        <a>Check out the Scripting Games at: http://scriptinggames.org </a>
                        </html>
                    "

                    # Combine the above pieces to a single HTML container
                    $htmlOut = $htmlHead + $htmlTable +$htmlTail

                    # Write HTML to file
                    $htmlOut | Out-File $Report
                }
            } # End if $Continue
        } # End ForEach $ComputerName
	} # End Process	

    End
    {
        # Show the HTML Report in a browser
        if ($Report) {
        # Report has been specified, check if there is a file
            if (Test-Path $Report) {
                Write-Verbose "Opening $Report ..."
                Start-Process -FilePath $Report
            }
        }
    } # End End :)
} # End Get-InventoryInfo