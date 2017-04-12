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
    try {
        $Release = Invoke-RestMethod https://github.com/PowerShell/PowerShell/releases.atom -ErrorAction Stop | Select-Object -First 1
    } catch {
        Write-Warning "Could not check for new version. $_ `n"
        break
    }
    $GitId = $Release.id -split "/" | Select-Object -Last 1
    $Download = -join("https://github.com",$Release.link.href)
    
    if($GitId -eq  $PSVersionTable.GitCommitId) {
        Write-Host "$GitId is the latest version. `n" -ForegroundColor Green
    } else {
        Write-Host "You are running $($PSVersionTable.GitCommitId) but $GitId is available!" -ForegroundColor Yellow
        Write-Host "Download from: $Download `n" -ForegroundColor Yellow
    }
}
Test-PSVersionGitHub
