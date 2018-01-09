function Read-GPGMessage {
    <#
    .SYNOPSIS
        Invokes 'gpg' command-line tool to decrypt messages.
    .DESCRIPTION
        This cmdlet is a wrapper for 'gpg --decrypt' to read encrypted messages.
    .EXAMPLE
        PS C:\> Read-GPGMessage -Message "----BEGIN PGP...."
        
        The -Message parameter accepts a GPG encrypted string, GPG will prompt for a password and the output is written to the pipeline.
    .EXAMPLE
        PS C:\> Get-Content .\a.txt -Raw | Read-GPGMessage 
        
        The -Message parameter accepts a GPG encrypted string, GPG will prompt for a password and the output is written to the pipeline.
    .EXAMPLE
        PS C:\> Read-GPGMessage -File .\a.txt -Output .\b.txt
        
        The file parameter specifies an input file that contains encrypted data, the output parameter specifies the destination file for the decrypted data.
    .INPUTS
        [string]
        As provided by Get-Content -Raw
    .OUTPUTS
        [string]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "Message"
    )]
    param (
        [Parameter(
            Position = 0,   
            ValueFromPipeline = $true,
            ParameterSetName = "Message")]
        [string]
        $Message,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "File")]
        [System.IO.FileInfo]
        $File,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "File")]
        [System.IO.FileInfo]
        $Output
    )
    process {
        switch ($PSBoundParameters.Keys) {
            "Message" { 
                $command = " `"$message`"  | gpg --decrypt"
            }
            "File" {
                $command = "gpg --decrypt $File"
             }
            "Output" {
                $command = "gpg --output $Output --decrypt $File"
             }
        }
        if($PSCmdlet.ShouldProcess($command, "Executing:")) {
            Invoke-Expression -Command $command
        }
    }    
}