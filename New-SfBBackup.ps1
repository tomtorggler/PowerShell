<#
.Synopsis
    Backup Skype for Business / Lync Server Data.
.DESCRIPTION
    This script exports Skype for Business / Lync Data and Settings according to the documentation availabe on TechNet.
    It is intended to be run as scheduled task, the Retention parameter can be used to indicate how long
    to keep existing backup files in the target directory.
.EXAMPLE
    .\New-SfBBackup.ps1 -PoolFqdn lyncpool01.example.com -Path \\SERVER\Share\CSBackup

    This example exports Lync config and saves it into a subfolder at \\SERVER\Share\CSBackup 
.EXAMPLE
    .\New-SfBBackup.ps1 -PoolFqdn lyncpool01.example.com -Path \\SERVER\Share\CSBackup -Retention 10

    This example exports Skype for Business / Lync config and saves it into a subfolder at \\SERVER\Share\CSBackup.
    It deletes existing backups in the destination direcotry if they are older than 10 days.
.ROLE
    The user must be member of the RTCUniversalServerAdmins group. 
.NOTES
    Author: Thomas Torggler; @torggler
    Date: 2018-03-17
    Version: 2.0
        2.0 Updated Name, verbose output
        1.1 Added Retention parameter and some error handling.
        1.0: Basics
    To-do: Multiple pools, File Store, Autodiscovery        
.LINK
    http://www.ntsystems.it/page/PS-Start-LyncBackupps1.aspx
.LINK
    http://technet.microsoft.com/en-us/library/hh202170.aspx
#>

#Requires -Version 3

[CmdletBinding(ConfirmImpact='Medium')]
Param
(
    # PoolFqdn, specify the fully qualified domain name of the Enterprise pool or the Servername of the Standard Server.
    [Parameter(Mandatory=$true, 
                Position=0)]
    [ValidateScript({[bool](Get-CsPool $_ -ErrorAction SilentlyContinue)})]
    $PoolFqdn,

    # Path, specify the target root folder for the backup. A new sub folder is created every time the script is executed
    [Parameter(Mandatory=$true, 
                Position=1)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    $Path,

    # Retention, specify a number of days indicating how long to keep existing backup files. Defaults to 90.
    [Parameter(Mandatory=$false, 
                Position=2)]
    [ValidateNotNullorEmpty()]
    [ValidateRange(1,65535)]
    [int]$Retention = 90,

    # LogFile, specify a path to a log file. The script will log information and erros to the file.
    [Parameter(Mandatory=$false, 
                Position=0)]
    [System.IO.FileInfo]
    $LogFile=(Join-Path -Path $Path -ChildPath 'log-New-SfBBackup.txt')
)

#region Initialize Logflie and import module    
    
    Remove-Item $LogFile -ErrorAction SilentlyContinue
    "$(Get-Date) New-SfBBackup started" | Add-Content $LogFile -Force
    Write-Host "LogFile: $LogFile" -ForegroundColor Yellow

    try {
        Import-Module Lync -ErrorAction Stop
    } catch {
        "$(Get-Date) Error importing Module: $($_.ErrorRecord)" | Add-Content $LogFile
        exit    
    }

#endregion


#region Create target directory to store the exported config files

    $TimeStamp = Get-Date -Format yyyy-mm-dd-hh-mm-ss

    try {
        $BackupDir = New-Item -Path $Path -ItemType Container -Name "SfBBackup-$TimeStamp" -ErrorAction Stop
        "$(Get-Date) Created Backup Target Directory at $($BackupDir.FullName)" | Add-Content $LogFile
    } catch {
        "$(Get-Date) Error creating Backup Target directory: $($_.ErrorRecord)" | Add-Content $LogFile
        exit
    }

#endregion

#region Export configuration

    try {
        Export-CsConfiguration -FileName (Join-Path -Path $BackupDir -ChildPath "CsConfiguration.zip") -ErrorAction Stop
        Write-Verbose "Export CS Configuration"
        "$(Get-Date) Export-CsConfiguration OK" | Add-Content $LogFile
    } catch {
        "$(Get-Date) Error running Export-CsConfiguration $($_.ErrorRecord)" | Add-Content $LogFile
    }

    try {
        Export-CsLisConfiguration -FileName (Join-Path -Path $BackupDir -ChildPath "CsLisConfiguration.zip") -ErrorVariable CsLisConfigurationError
        Write-Verbose "Export CS LIS Configuration"
        "$(Get-Date) Export-CsLisConfiguration OK" | Add-Content $LogFile
    } catch {
        "$(Get-Date) Error running Export-CsLisConfiguration $($_.ErrorRecord)" | Add-Content $LogFile
    }

    try {
        Export-CsUserData -PoolFQDN $PoolFqdn -FileName (Join-Path -Path $BackupDir -ChildPath "CsUserData.zip") -ErrorVariable CsUserDataError
        Write-Verbose "Export CS UserData"
        "$(Get-Date) Export-CsUserData OK" | Add-Content $LogFile
    } catch {
        "$(Get-Date) Error running Export-CsUserData $($_.ErrorRecord)" | Add-Content $LogFile
    }
    
    try {
        Export-CsRgsConfiguration -Source "ApplicationServer:$PoolFqdn" -FileName (Join-Path -Path $BackupDir -ChildPath "CsRgsConfiguration.zip") -ErrorVariable CsRgsConfigurationError
        Write-Verbose "Export CS RGS Configuration"
        "$(Get-Date) Export-CsRgsConfiguration OK" | Add-Content $LogFile
    } catch {
        "$(Get-Date) Error running Export-CsRgsConfiguration $($CsRgsConfigurationError.ErrorRecord)" | Add-Content $LogFile
    }

#endregion

#region Delete existing backups

    if ($Script:Error) {
        Write-Verbose "Encountered $($Script:Error.Count) errors, skip deleting existing files."
        "$(Get-Date) Encountered $($Script:Error.Count) errors, skip deleting existing files." | Add-Content $LogFile
    } else {
        Write-Verbose "No errors encountered, delete existing files."
        $exstingBackups = Get-ChildItem $Path -Directory -Filter "SfBBackup-*"
        $existingBackupsToDelete = $exstingBackups | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-$Retention)}
 
        foreach ($Backup in $existingBackupsToDelete) {
            try {
                Remove-Item -Path $Backup.FullName -Recurse -ErrorAction Stop
                Write-Verbose "Deleting $($Backup.FullName) "
                "$(Get-Date) Deleted existing backup: $($Backup.FullName)" | Add-Content $LogFile 
            } catch {
                "$(Get-Date) Error deleting existing backup: $($_.ErrorRecord)" | Add-Content $LogFile
            }               
        }
    }

#endregion

"$(Get-Date) New-SfBBackup ended with $($Script:Error.Count) errors." | Add-Content $LogFile