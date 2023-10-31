# Create a symbolic link for the file 
# mac
# mkdir /Users/tto/.config/powershell
# ln -s /Users/tto/git/PowerShell/Microsoft.PowerShell_profile_osx.ps1 /Users/tto/.config/powershell/Microsoft.PowerShell_profile.ps1
# bash on win 10
# mkdir /home/tto/.config/powershell
# Copy-Item /mnt/c/Users/tto/OneDrive/_psscripts/git/PowerShell/Microsoft.PowerShell_profile_osx.ps1 $Profile -Force

# Update PATH variable for Mac so that I can run most bash commands in PS 
$addToPath = @(
    ":/usr/local/bin",
    "/opt/homebrew/opt/ruby/bin",
    "/opt/homebrew/bin",
    "/opt/homebrew/sbin"
)

$env:PATH += $addToPath -join ":"

# import modules for powercli
function Import-PowerCliModules {
    Import-Module PowerCLI.Vds, PowerCLI.ViCore
}
New-Alias -Name ipcli -Value Import-PowerCliModules

# check if a new release of PowerShell Core is available on GitHub
function Test-PSVersionGitHub {
    try {
        # get latest release from github atom feed
        $Release = Invoke-RestMethod https://github.com/PowerShell/PowerShell/releases.atom -ErrorAction Stop | Select-Object -First 1
    } catch {
        Write-Warning "Could not check for new version. $_ `n"
        break
    }
    # extract information from atom response
    $GitId = $Release.id -split "/" | Select-Object -Last 1
    $Download = -join("https://github.com",$Release.link.href)
    # Add information to dictionary for output
    $output = [ordered]@{
        "PSVersion" = $PSVersionTable.PSVersion;
        "GitCommitId" = $PSVersionTable.GitCommitId;
        "GitHubReleaseVersion" = $GitId;
        "GitHubReleaseLink" = $Download;
    }
    Write-Output (New-Object -TypeName psobject -Property $output)
}
# powershell started checking for newer versions by itself
# Test-PSVersionGitHub

. ~/git/PowerShell/Microsoft.PowerShell_profile.ps1