#######
### The actual $PROFILE only contains the following line
### . $env:USERPROFILE\Git\PowerShell\Microsoft.PowerShell_profile.ps1
### to dot-source this file
######

## Aliases... because of muscle memory :/
New-Alias -Name ll -Value Get-ChildItem -ErrorAction SilentlyContinue

Import-Module C:\Users\thomas.torggler\AppData\Local\Apps\2.0\9V9HVHDB.2KG\691XWNER.8NB\micr..tion_d8f8f667ee342b5c_0010.0000_6b4a13fd451b1c00\Microsoft.Exchange.Management.ExoPowershellModule.dll -ErrorAction SilentlyContinue

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

function Set-DnsDhcp {
    param(
        $InterfaceIndex = 4
    )
    $command = "Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ResetServerAddresses"
    Invoke-AsAdmin $command
}

function Get-InternetProxy {
    param(
        [switch]$ShowAutoConfig
    )
    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"        
    Get-ItemProperty -path $regKey | Select-Object -Property ProxyEnable,ProxyServer,ProxyOverride,AutoConfigURL,@{n="AutoDetect";E={Get-InternetProxyAutoDetect}}
    if($ShowAutoConfig) {
        $path = Get-ItemProperty -path $regKey | Select-Object -ExpandProperty AutoConfigURL
        if($path -match "file:") {
            Get-Content -Path $($path.replace("file://",""))
        }
    }               
}
Function Disable-InternetProxy {
    param(
        [switch]$ClearAutoConfigUrl
    )
    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"        
    Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 0
    Set-ItemProperty -Path $regKey -Name ProxyServer -Value ""
    if ($ClearAutoConfigUrl0) {
        Set-ItemProperty -Path $regKey -Name AutoConfigURL -Value ""
    }               
}
Function Enable-InternetProxy {
    param(
        $proxyServer = "localhost:8118",
        $AutoConfigFile
    )
    $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"        
    Set-ItemProperty -Path $regKey -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regKey -Name ProxyServer -Value $proxyServer
    if($AutoConfigFile) {
        Set-ItemProperty -Path $regKey -Name AutoConfigURL -Value $AutoConfigFile
    }
}
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

function Set-SecurityProtocol {
    param($Protocol,[switch]$Default)
    if($default) {
        [net.servicepointmanager]::SecurityProtocol = [System.Security.Authentication.SslProtocols]::Default
    } else {
        [net.servicepointmanager]::SecurityProtocol = $Protocol
    }
}
function Get-SecurityProtocol {
    [net.servicepointmanager]::SecurityProtocol
}

if($PSEdition -ne "Core"){
    $connectedIf = Get-NetIPInterface -ConnectionState Connected | Where-Object ifIndex -ne 1
    $dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $connectedIf.IfIndex | select -ExpandProperty serveraddresses) -join ", "
}
$write = "
---
Hello $($env:USERNAME) @ $($env:COMPUTERNAME) [$($PSVersionTable.BuildVersion)]

Remeber: Set-DnsOpen, Set-DnsDhcp, Get-DnsClientServerAddress, Get-InternetProxy
HidServ: zik25npqnzrdl3r7.onion 6slsw42zq5n76gt7.onion uhhikmyycppwnh3b.onion

Connection Alias $(($connectedIf.InterfaceAlias | Select-Object -Unique) -join ", ") 
Connection Index $(($connectedIf.IfIndex | Select-Object -Unique) -join ", ")
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


function prompt 
{ 
    $pss = Get-PSSession | Where-Object Availability
    $cwd = (Get-Location).Path        
    if($pss) {
        $WindowTitle = "Connected to: " + ($pss.ComputerName -join ", ") 
        $info = $pss.Name -join ", " 
    } else {
        $WindowTitle = $cwd
        $info = "PS"
    }
    $host.UI.RawUI.WindowTitle = $WindowTitle
    $host.UI.Write("Yellow", $host.UI.RawUI.BackGroundColor, "[$info]")
    " $($cwd.Replace($env:USERPROFILE,"~"))$('>' * ($nestedPromptLevel + 1)) ";
}


function Get-InternetProxyAutoDetect {
    [CmdletBinding()]
    param()

    $RegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\" 
    $DefaultConnection = $(Get-ItemProperty $RegKey).DefaultConnectionSettings 

    if ($($DefaultConnection[8] -band 8) -ne 8) { 
        Write-Verbose "Auto Detection disabled for Default Connection"
        Write-Output $false 
    } else { 
        Write-Verbose "Auto Detection enabled for Default Connection"
        Write-Output $true 
    }
}

function Enable-InternetProxyAutoDetect {
    [CmdletBinding()]
    param()

    $RegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\" 
    $DefaultConnection = $(Get-ItemProperty $RegKey).DefaultConnectionSettings 

    $DefaultConnection[8] = $DefaultConnection[8] -bor 8 
    $DefaultConnection[4]++ 

    Write-Verbose "Enabling Proxy auto detection for Default Connection"
    Set-ItemProperty -Path $RegKey -Name DefaultConnectionSettings -Value $DefaultConnection 
}

function Disable-InternetProxyAutoDetect {
    [CmdletBinding()]
    param()

    $RegKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\" 
    $DefaultConnection = $(Get-ItemProperty $RegKey).DefaultConnectionSettings 

    $mask = -bnot 8 
    $DefaultConnection[8] = $DefaultConnection[8] -band $mask 
    $DefaultConnection[4]++ 
    
    Write-Verbose "Disabling Proxy auto detection for Default Connection"
    Set-ItemProperty -Path $RegKey -Name DefaultConnectionSettings -Value $DefaultConnection 
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