function Find-UniuqeClientIP {
    <#
    .Synopsis
       Find and list unique client IPs in IIS logs.
    .DESCRIPTION
       This function was created for the Scripting Games 2013.
       This function uses regular expression to find IP addresses withing one or more IIS log files.
       You need to specify a folder containing one or more logfiles with a specified extension. The Filter parameter 
       can be used to specify a file extension like *.log, *.txt.
       The Pattern 
       parameter can be used to select a subset of client IP addresses.
    .EXAMPLE
       Find-UniqueClientIP -Path C:\temp\LogFiles

       This example finds unique client IP addresses in all .log files within C:\temp\LogFile    
    .EXAMPLE
       Find-UniqueClientIP -Path C:\temp\LogFiles -Filter *.txt

       This example finds unique client IP addresses in all .txt files within C:\temp\LogFile.
    .EXAMPLE
       Find-UniqueClientIP -Path C:\temp\LogFiles -Pattern "192.168.*" -Verbose
       
       This example finds unique client IP addresses in all .log files within C:\temp\LogFile.
       Only IP addresses starting with "192.168." are included in the output.
    .OUTPUTS
       [string]
    #>
    [CmdletBinding(PositionalBinding=$true,
                  ConfirmImpact='Medium')]
    [OutputType([string])]
    Param
    (
        # Specify a folder containing one or more IIS log files with *.log extension.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({Test-Path -Path $PSItem -PathType Container})]
        [Alias("LogFolder")]
        [System.IO.DirectoryInfo]
        $Path,

        # Specify a string filter to select an subset of client IP addresses.
        [Parameter(Mandatory=$false,                 
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("IpAddressPattern")]
        [string]
        $Pattern = "*",

        # specify which file extensions to include, like *.txt. Default to *.log.
        [Parameter(Mandatory=$false,                 
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\*\.\w{3}$')]
        [Alias("Extension")]
        [string]
        $Filter = "*.log"
    )

    # regex used to match ip addersses in logfiles
    $RegExPattern = '\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'

    # initialize variable and build the path used with select-string
    $filtered = @()
    $LogPath = Join-Path -Path $Path -ChildPath $Filter
    Write-Verbose "Path is: $LogPath"
       
    # use -matchall to get all IPs, first match is "s-ip"; second match is "c-ip"; using strings makes it easier
    $PatternMatches = Select-String -Path $LogPath -Pattern $RegExPattern -AllMatches | Select-Object -Property @{n="ServerIP";e={$PSItem.matches[0].toString()}},@{n="ClientIP";e={$PSItem.matches[1].toString()}}
    
    Write-Verbose "Applying filter pattern: $Pattern"
   
    foreach ($match in $PatternMatches) {
        # filter the ClientIP, this is 50% faster than using where-object
        if ($match.clientIP -like $Pattern) {
            # save all objects witch matching ClientIP in a container
            $filtered += $match
        }
    }
    # writing string values to the pipeline
    $filtered.clientIP | select -Unique
}