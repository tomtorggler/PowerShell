#######
### The actual $PROFILE only contains the following line
### . $env:USERPROFILE\Git\PowerShell\Microsoft.PowerShell_profile.ps1
### to dot-source this file
######

## Aliases... because of muscle memory :/
New-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue

#Import-Module C:\Users\thomas.torggler\AppData\Local\Apps\2.0\9V9HVHDB.2KG\691XWNER.8NB\micr..tion_d8f8f667ee342b5c_0010.0000_6b4a13fd451b1c00\Microsoft.Exchange.Management.ExoPowershellModule.dll -ErrorAction SilentlyContinue

function Invoke-AsAdmin {
    param($command)
    Start-Process powershell -Verb RunAs -ArgumentList "-noprofile $command"
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

function Set-SecurityProtocol {
    param(
        [System.Security.Authentication.SslProtocols]$Protocol,
        [switch]$Default
    )
    if($default) {
        [net.servicepointmanager]::SecurityProtocol = [System.Security.Authentication.SslProtocols]::Default
    } else {
        [net.servicepointmanager]::SecurityProtocol = $Protocol
    }
}
function Get-SecurityProtocol {
    [net.servicepointmanager]::SecurityProtocol
}

$connectedIf = Get-NetIPInterface -ConnectionState Connected | Where-Object ifAlias -NotMatch "loopback|veth|bluetooth"
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


function Send-MailJetMail {
    [cmdletbinding()]
	param(
        [string]$Sender = "notification@tomt.it",
        [string]$Recipient,
        [string]$Subject,
        [string]$Text,
        [string]$ApiKey,
        [string]$Secret
    )
    $body = @{
        Messages = @(@{
            From = @{
                Email = $sender
                Name = "Notification"
            }
            To = @(@{
                Email = $recipient
                Name = ""
            })
            Subject = $subject
            TextPart = $text
        })
    
    } | ConvertTo-Json -Depth 4
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiKey,$Secret)))
	$Result = Invoke-RestMethod -Uri "https://api.mailjet.com/v3.1/send" -ContentType "application/json" -body $body -Method POST -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UseBasicParsing
    if($Result) {
        $Result.Messages
    }
}


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

function Get-PublicIP {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(1,8)]
        [int]
        $Timeout = 1
    )
    # why does irm output an error message even if silentlycontinue?
    [ipaddress]$ip4 = Invoke-RestMethod http://ipv4.myip.dk/api/Info/IPv4Address -TimeoutSec $Timeout -ErrorAction SilentlyContinue
    [ipaddress]$ip6 = Invoke-RestMethod http://ipv6.myip.dk/api/Info/IPv6Address -TimeoutSec $Timeout -ErrorAction SilentlyContinue
    $out = @{
        IPv4 = $ip4.IPAddressToString
    }
    if ($ip6.AddressFamily -eq "InterNetworkV6"){
        $out.add("IPv6",$ip6.IPAddressToString)
    }
    New-Object -TypeName psobject -Property $out
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
    Write-Output (New-Object -TypeName psobject -Property $output)
}
if($iscoreclr){
    Test-PSVersionGitHub
}
