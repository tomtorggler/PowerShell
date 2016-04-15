
<#PSScriptInfo

.VERSION 0.1

.GUID c3e1577a-fb7f-427b-b423-8126ee17dd9b

.AUTHOR @torggler

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<#
.Synopsis
    A wrapper for the DiskSpd utility
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>

[CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                PositionalBinding=$false,
                ConfirmImpact='Medium')]
[Alias('diskspd')]
[OutputType([psobject])]
Param
(
    # Specify the path to the Diskspd.exe file
    [Parameter(Mandatory=$false, 
                Position=0,
                ParameterSetName='Parameter Set 1')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo] 
    $Path=(Join-Path -Path $env:USERPROFILE -ChildPath "Downloads\Diskspd-v2.0.15\amd64fre\diskspd.exe"),

    # Specify a filepath where the testfile will be created. Default is TEMP
    [System.IO.FileInfo]
    $TestFilePath = (Join-Path -Path $env:TEMP -ChildPath "diskspdtest.dat"),

    # Specify a path to the LogFile    [Parameter(Mandatory=$false)]    [ValidateNotNull()]    [ValidateNotNullOrEmpty()]    [System.IO.FileInfo]    $LogFile="$env:TEMP\log-Invoke-DiskSpd.txt",

    # Specify the filesize for the test file. Default is 1GB
    [int]
    $TestFileSize = 1GB,

    # Specify the block size in bytes. Default is 4kb
    [int]
    $BlockSize = 4kb,

    # Specify percentage of writes. Default is 50. 0 indicates 100% read operations.
    [int]
    [ValidateRange(0,100)]
    $WritePercentage = 50,

    [int]
    $OutstandingIos,

    # Specify duration in seconds. Default is 60.
    [int]
    [ValidateRange(1,86400)]
    $Duration = 60,

    # Specify warmup duration before measurement starts in seconds. Default is 5 seconds.
    [int]
    [ValidateRange(1,86400)]
    $WarmUp = 5,

    # Specify number of threads to use for workload. Default is number of CPU cores.
    [int]
    $Threads,

    # Use a buffer, filled with random data, of the specified size, as source for write operations.
    # If not specified, a repeating pattern is used to fill write buffers.
    [int]
    $RandomWriteBufferSize,

    # Delete the testfile after finishing. If not specified, the testfile will not be deleted and can be used
    # for additional tests.
    [switch]
    $RemoveTestFile,

    # Do not capture latency data. Default is capture latency.
    [switch]
    $NoLatency,

    # Enable software and hardware caching. If TestFileSize fits into RAM, this essentially measures RAM performance. 
    # Default is both soft/hardware caching disabled.
    [switch]
    $EnableCaching,

    # Random IO, if not specified, sequential-interlocked is used.
    [switch]
    $Random

)

#region set environment    # save the current location, then change location to the ResKit directory    $CurrentLocation = Get-Location    Set-Location $Path.DirectoryName    Write-Verbose "Changed Location to $($Path.DirectoryName)"    # delete existing logfile, and create a new one    Remove-Item -Path $logfile -ErrorAction SilentlyContinue    "$(Get-Date) Invoke-DiskSpd started" | Add-Content $LogFile    # Write location of logfile to host    Write-Host "LogFile: $LogFile" -ForegroundColor Yellow

#endregion

#region DiskSpd parameters

    $DiskSpd = ".\diskspd.exe"
    $DiskSpdParams = " -d$Duration -W$WarmUp -w$WritePercentage -b$BlockSize -c$TestFileSize"

    if(-not($NoLatency)) {
        $DiskSpdParams += " -L"
    }

    if(-not($EnableCaching)){
        $DiskSpdParams += " -h"
    }

    if($RandomWriteBufferSize) {
        $DiskSpdParams += " -Z$RandomWriteBufferSize"
    }

    if($OutstandingIos) {
        $DiskSpdParams += " -o$OutstandingIos"
    }

    if($Random) {
        $DiskSpdParams += " -r"
    } else {
        $DiskSpdParams += " -si"
    }

    if($Threads) {
        $DiskSpdParams += " -t$Threads"
    } else {
        # borrowed from diskspdbatch (technet gallery)
        # get CPU cores to determine number of threads (non-hyper-threaded)
        $processors = Get-CimInstance -ComputerName localhost Win32_Processor
        $Cores = 0
        if ( @($processors)[0].NumberOfCores) {
            $Cores = @($processors).Count * @($processors)[0].NumberOfCores
        } else {
            $Cores = @($processors).Count
        }
        $DiskSpdParams += " -t$Cores"
    }

#endregion DiskSpd params

Write-Verbose "Invoking $DiskSpd $DiskSpdParams `"$TestFilePath`""

$DiskSpdOutput = Invoke-Expression -Command ($DiskSpd + $DiskSpdParams + " " + $TestFilePath) 
$DiskSpdOutput

if ($RemoveTestFile) {
    Write-Verbose "Removing testfile at $TestFilePath"
    Remove-Item $TestFilePath
}
#region reset environment    # set location back to where we have been originally    Set-Location $CurrentLocation    Write-Verbose "Changed Location back to original"    "$(Get-Date) Invoke-DiskSpd finished" | Add-Content $LogFile

#endregion
