function Start-ArchiveLog {
    <#
    .Synopsis
       Archive log files older than 90 days. 
    .DESCRIPTION
       This function was created for the Scripting Games 2013.
       This function can be used to move ".log" files from one directory to another directory, local or on a remote server. 
       The -OlderThan parameter can be used to specify which files should be moved. 
    .EXAMPLE
       Start-ArchiveLog -LogPath C:\Application\Log -ArchivePath \\Server\Archive -Verbose

       This example moves all files with a .log extension from C:\Application\Log and subfolders to \\Server\Archive. It moves files with a CreationTime older than 90 days.
    .EXAMPLE
       Start-ArchiveLog -LogPath C:\Application\Log -ArchivePath D:\Archive -OlderThan 20

       This example moves all files with a .log extension from C:\Application\Log and subfolders to D:\Archive, the OlderThan parameter is used to move files with a CreationTime of 20 days ago.
    .EXAMPLE
       Start-ArchiveLog -LogPath C:\Application\Log -ArchivePath D:\Archive -Force

       This example moves all files with a .log extension from C:\Application\Log and subfolders to D:\Archive, the -Force switch overwrites existing files in the destination directory.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    
    Param
    (
        # Specify the path containing logs that should be archived. Files will be moved from LogPath to ArchivePath.
        [Parameter(Mandatory=$true, 
                    Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_})]
        [System.IO.DirectoryInfo]
        $LogPath,

        # Specify the path where the archive is located. Files will be moved from LogPath to ArchivePath.
        [Parameter(Mandatory=$true, 
                    Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path $_})]
        [System.IO.DirectoryInfo]
        $ArchivePath,

        # Set the Creationtime in days.
        [Parameter(Mandatory=$false, 
                    Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [int]
        $OlderThan = '90',

        # Use the -Force switch parameter to overwrite existing files in the destination directory.
        [switch]
        $Force
    )

    Begin
    {
    } 
    Process
    {
        # Get the files in the folders, only select files with a .Log extension and the files which were created $OlderThan days ago
        $LogFiles = Get-ChildItem $LogPath.FullName -File -Recurse | Where-Object {
            ($_.Extension -eq ".log") -and ($_.CreationTime -lt (Get-Date).AddDays(-$OlderThan))
        }

        # Check if $LogFiles actually contains something
        if (-not($LogFiles -eq $null)) {
            # Get the parent directories of the log files selected before
            $Parents = $LogFiles.Directory | Select-Object -Unique -ExpandProperty Name
        
            # Enumerate parent directories and check if the respective directory exists in the destination.
            # If parent dir doesn't exist, try to create it. If creation fails, output the error and set $Continue to $false so the script stops.
            foreach ($Parent in $Parents) {
                try {
                    if (-not(Test-Path $ArchivePath\$Parent -ErrorAction Stop)) {
                        Write-Verbose "Destination Folder doesn't exist, trying to create: $ArchivePath\$Parent"
                        New-Item -Path $ArchivePath -Name $Parent -ItemType Directory -ErrorAction Stop | Out-Null
                        $Continue = $true
                    } else {
                        Write-Verbose "Destination Folder exists: $ArchivePath\$Parent"
                        $Continue = $true
                    }
                } catch {
                    $ErrorMsg = "Could not create folder $ArchivePath\$Parent : $($_.Exception.Message)"
                    Write-Warning $ErrorMsg
                    $Continue = $false
                }
            } # end foreach $Parents

        } else {
            # If no files have been found, provide a Verbos message and exit.
            Write-Verbose "No files to move, bye"
            $Continue = $false
        }

        # If everything went fine ($Continue is true) go ahead and try to move the files
        if ($Continue) {
        
            # Enumerate LogFiles so we can use the Directory property to get the parent directory
            foreach ($LogFile in $LogFiles) {
            
                # support for -whatIf
                if ($pscmdlet.ShouldProcess("$($LogFile.FullName)", "Move to $ArchivePath\$($LogFile.Directory.Name)")) {
                    try {
                        # HashTable for -force parameter
                        $parms = @{'Force'=$Force}
                        Move-Item @parms -Path $($LogFile.FullName) -Destination $ArchivePath\$($LogFile.Directory.Name) -ErrorAction Stop
                    } catch {
                        $ErrorMsg = "Could not move file $($LogFile.FullName) to $ArchivePath\$($LogFile.Directory.Name) : $($_.Exception.Message)"
                        Write-Warning $ErrorMsg            
                    }
                } # end if -whatif
            } # end foreach $LogFiles
        } # end if $continue
    }
    End
    {
    }
}