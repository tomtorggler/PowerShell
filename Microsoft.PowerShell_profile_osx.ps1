# Create a symbolic link for the file 
# ln -s /Users/ttor/git/PowerShell/Microsoft.PowerShell_profile_osx.ps1 /Users/ttor/.config/powershell/Microsoft.PowerShell_profile.ps1

# Update PATH variable for Mac so that I can run most bash commands in PS 
$env:PATH += ":/usr/local/bin"

# Test - upadte TAK with "cross-platform" functions
function Show-HostsFile {
    [CmdletBinding()]
    param()
    if($PSVersionTable.PSEdition -eq "Core") {
        Write-Verbose "PSEdition is $($PSVersionTable.PSEdition)"
        Get-Content /etc/hosts

    } else {
        Write-Verbose "PSEdtion is $($PSVersionTable.PSEdition)"
        Get-Content C:\Windows\System32\Drivers\etc\hosts    
    }
}

function Test-SSLConnection {
    [CmdletBinding()]
    param($hostname,$port)
    if($PSVersionTable.PSEdition -eq "Core") {
        Write-Verbose "$($PSVersionTable.PSEdition)"
        Write-Verbose "command is: openssl s_client -connect -join $(($hostname,":",$port))"
        
        openssl s_client -connect $(-join ($hostname,":",$port))

    } else {
        Write-Verbose "PSEdtion is $($PSVersionTable.PSEdition)"
        Get-Content C:\Windows\System32\Drivers\etc\hosts    
    }
}

