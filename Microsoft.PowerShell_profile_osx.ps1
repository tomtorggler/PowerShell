# Create a symbolic link for the file 
# ln -s /Users/ttor/git/PowerShell/Microsoft.PowerShell_profile_osx.ps1 /Users/ttor/.config/powershell/Microsoft.PowerShell_profile.ps1

# Update PATH variable for Mac so that I can run most bash commands in PS 
$env:PATH += ":/usr/local/bin"

# import modules for powercli
function Import-PowerCliModules {
    Import-Module PowerCLI.Vds, PowerCLI.ViCore
}
New-Alias -Name ipcli -Value Import-PowerCliModules

# check if newer release is available on GitHub
function Test-PSVersionGitHub {
    [cmdletbinding()]
    param()
    try {
        $Release = Invoke-RestMethod https://github.com/PowerShell/PowerShell/releases.atom -ErrorAction Stop | Select-Object -First 1
    } catch {
        Write-Warning "Could not check for new version. $_ `n"
        break
    }
    $GitId = $Release.id -split "/" | Select-Object -Last 1
    $Download = -join("https://github.com",$Release.link.href)
    
    if($GitId -eq  $PSVersionTable.GitCommitId) {
        Write-Verbose "$GitId is the latest version."
    } else {
        Write-Verbose "You are running $($PSVersionTable.GitCommitId) but $GitId is available!"
    }
    New-Object -TypeName psobject -Property ([ordered]@{
        InstalledVersion=$($PSVersionTable.GitCommitId);
        GitHubVersion=$GitId;
        RealeaseLink=$Download
    })
}
Test-PSVersionGitHub
