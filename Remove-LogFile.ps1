<#PSScriptInfo

.VERSION 1.0.0

.GUID a1ba81d3-e859-4998-b6ff-c9b8413c7316

.AUTHOR @torggler

.TAGS Logs

.PROJECTURI https://ntsystems.it/PowerShell/Remove-LogFile/

#>
<#
.SYNOPSIS
   Deletes log files.
.DESCRIPTION
   Deletes log files, parameters can be used to specify the root folder, whether or not to include subfolders, a file extension filter and the age.
   This is intended to be run as scheduled task to regularly clean-up log files. 
.EXAMPLE
   PS C:\> .\Remove-LogFile.ps1 -Path C:\inetpub\logs -Age 7 -Recurse

   This example removes all *.log files older than 7 days from C:\inetpub\logs and any subfolders.
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
   Author: Thomas Torggler; @torggler
   Date: 2014-04-30
   Version: 1.1
        1.0: Basic Script
        1.1: handle if no files to delete.
    Notes: If PowerShell Version 2.0 is used, remove the -file Parameter from Get-Childitem
.LINK
    https://ntsystems.it/PowerShell/Remove-LogFile/
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param
(
    # Specify folder in which logs will be deleted
    [Parameter(Mandatory=$true, 
                Position=0)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    $Path,

    # Specify a number of days. Files with a LastWriteTime older than this will be deleted.
    [Parameter(Mandatory=$false, 
                Position=1)]
    [ValidateNotNullorEmpty()]
    [ValidateRange(1,65535)]
    [int]$Age = 90,

    # Specify file extension filter. Defaults to '*.log'.
    [Parameter(Mandatory=$false, 
                Position=2)]
    [ValidatePattern('^\*\.\w{3}$')]
    [string]
    $Filter = '*.log',
    
    # Specify a path to a log file. The script will log information and erros to the file.
    [Parameter(Mandatory=$false)]
    [System.IO.FileInfo]
    $LogFile="$env:temp\log-RemoveLogFile.ps1",

    # Include subfolders.
    [switch]
    $Recurse
)
# Clean and initialize Log File
Remove-Item $LogFile -ErrorAction SilentlyContinue -WhatIf:$false
"$(Get-Date) Remove-LogFile started!" | Add-Content $LogFile -WhatIf:$false
Write-Host "LogFile: $LogFile" -ForegroundColor Yellow

$filesToDelete = Get-ChildItem -Path:$Path -File -Recurse:$Recurse -Filter:$Filter | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-$Age)}

if ($filesToDelete) {

    "$(Get-Date) Found $($filesToDelete.Count) files to delete." | Add-Content $LogFile

    foreach ($file in $filesToDelete) {
        if ($pscmdlet.ShouldProcess("$($File.FullName)", "Delete"))
            {
                Remove-Item -Path $file.FullName
                "$(Get-Date) Removed $($file.FullName)" | Add-Content $LogFile
            }
    }
} else {
    "$(Get-Date) Nothing to delete." | Add-Content $LogFile -WhatIf:$false
}

"$(Get-Date) Remove-LogFile ended!" | Add-Content $LogFile -WhatIf:$false