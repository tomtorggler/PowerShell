
function Read-KeybasePgpMessage {
    <#
    .SYNOPSIS
        A wrapper for the keybase tool.
    .DESCRIPTION
        This function provides a wrapper for "keybase pgp decrypt" to make it easier to use.
    .EXAMPLE
        PS > Read-KeybasePgpMessage -File ./Downloads/mail.txt
        
        This example tries to decrypt the mail.txt file using "keybase pgp decrypt -i mail.txt" 
    .EXAMPLE
        PS > Read-KeybasePgpMessage .\Downloads | Invoke-Keybase

        This example first gets all items in the ./Downloads folder and then tries to decrypt each one using "keybase pgp decrypt -i <filename>"
    .INPUTS
        [System.IO.FileInfo]
    .OUTPUTS
        [PSObject]
    .NOTES
        Autor: @torggler
        Tested on Desktop and Core.
    #>
    [CmdletBinding()]
    param (    
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Path,
        
        [Parameter(ValueFromPipeline=$True)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $File,

        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $OutFile

    )
    begin {
        # Set default value for path parameter only if -Path is not used.
        if(-not($PSBoundParameters.Path) -and $PSEdition -eq "Core") {
            $Path = "/usr/bin/keybase"
            $env:HOMEPATH = $env:HOME
            Write-Verbose "Running on PS $PSEdition and using $Path"
        } elseif(-not($PSBoundParameters.Path)) {
            $Path = "C:\Users\Thomas\AppData\Local\Keybase\keybase.exe"
            Write-Verbose "Running on PS $PSEdition and using $Path"
        } else {
            Write-Verbose "Running on PS $PSEdition and using $Path"
        }
    }
    process {
        Write-Verbose "Processing $File"

        if ($Message) {
            $KBParams = " pgp decrypt -m `"$Message`" "
        } elseif ($File){
            $KBParams = " pgp decrypt -i $($file.FullName)"
        }
        
        #$KBResult = Invoke-Expression -Command ("$Path $KBParams")
        $tmpout = Join-Path $env:HOMEPATH -ChildPath keybaseout.txt
        $tmperr = Join-Path $env:HOMEPATH -ChildPath keybaseerror.txt
        
        Start-Process -FilePath $Path -ArgumentList $KBParams -NoNewWindow -RedirectStandardOutput $tmpout -RedirectStandardError $tmperr -Wait
        
        $KBResult = Get-Content -Path $tmpout -Encoding UTF8
        if((Get-Item $tmperr).Length -ne 0) {
            $KBResult = Get-Content -Path $tmperr -Encoding UTF8
        }
        Remove-Item $tmpout,$tmperr -ErrorAction SilentlyContinue

        $output = @{
            CommandLine = "$($Path.Name) $KBParams";
            InFile = $File.FullName;
            Output = $KBResult;
        }
        if($OutFile) {
            $KBResult | Set-Content -Path $OutFile -Force
        } else {
            Write-Output (New-Object -TypeName psobject -Property $output)
        }   
    }
}
