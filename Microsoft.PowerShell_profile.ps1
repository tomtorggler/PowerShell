#######
### The actual $PROFILE only contains the following line to dot-source this file
### . $env:USERPROFILE\Git\PowerShell\Microsoft.PowerShell_profile.ps1
######
$host.PrivateData.ErrorForegroundColor = 'white'
## Aliases... because of muscle memory :/
New-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue

function Invoke-AsAdmin {
    param($command)
    Start-Process pwsh -Verb RunAs -ArgumentList "-noprofile $command"
}

function Set-DnsOpen { 
    param(
        $InterfaceIndex = 4
    )
    $command = "Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ('208.67.222.222','208.67.220.220','2620:0:ccc::2','2620:0:ccd::2')"
    Invoke-AsAdmin $command
}

function Set-DnsCloudflare { 
    param(
        $InterfaceIndex = 4
    )
    $command = "Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses ('1.1.1.1','1.0.0.1','2606:4700:4700::1111','2606:4700:4700::1001')"
    Invoke-AsAdmin $command
}

function Set-DnsDhcp {
    param(
        $InterfaceIndex = 4
    )
    $command = "Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ResetServerAddresses"
    Invoke-AsAdmin $command
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

dir  "$env:USERPROFILE\Git\IT-Pro-Trashcan\tto\tools" -Filter *.ps1 | %{ . $_.FullName }
Set-SecurityProtocol -Protocol Tls12

$connectedIf = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object -Property RouteMetric -Descending 
if($connectedIf){
    $dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $connectedIf.IfIndex | Select-Object -ExpandProperty serveraddresses -Unique) -join ", "
}

$write = "
---
IfAlias: $(($connectedIf.InterfaceAlias | Select-Object -Unique) -join ", ") 
IfIndex: $(($connectedIf.IfIndex | Select-Object -Unique) -join ", ")
DNS Servers: $dnsServers
Security Protcols: $(Get-SecurityProtocol)
---
"
Write-Host $write -ForegroundColor Yellow



function prompt {
    $pss = Get-PSSession | Where-Object Availability
    $cwd = (Get-Location).Path        
    if($pss) {
        $WindowTitle = "Connected to: " + ($pss.ComputerName -join ", ") 
        $info = $pss.ComputerName -join ", "
        $info += ": #$($MyInvocation.HistoryId)"
    } else {
        $WindowTitle = $cwd
        $info = "PS: #$($MyInvocation.HistoryId)"
    }
    if($Global:WindowTitlePrefix){
        $WindowTitle = $Global:WindowTitlePrefix,$WindowTitle -join ": "
    }
    $host.UI.RawUI.WindowTitle = $WindowTitle
    $host.UI.Write("Yellow", $host.UI.RawUI.BackGroundColor, "[$info]")
    " $($cwd.Replace($env:USERPROFILE,"~"))$('>' * ($nestedPromptLevel + 1)) ";
}

function Set-WindowTitle($String) {
    $Global:WindowTitlePrefix = $String
}


function Get-JekyllTitle {
    [CmdletBinding()]
    param (
        [string]
        $String
    )       
    process {
        $date = Get-Date -Format "yyyy-MM-dd"
        $date,($string.ToLower() -replace "\W+","-") -join "-"   
    }
}


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
    if($output.PSVersion -ne $output.GitCommitId){
        Write-Output (New-Object -TypeName psobject -Property $output)
    }
}
if($iscoreclr){
    Test-PSVersionGitHub
}

$env:Path += ";C:\Users\ThomasTorggler\OneDrive - Experts Inside AG\Tools"