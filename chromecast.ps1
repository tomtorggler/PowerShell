function Get-ChromeCastDevice {
[cmdletbinding()]
param($ip)
$p = @{
    Method = "get"
    ContentType = "application/json" 
    #Uri = "http://{0}:8008/setup/eureka_info?options=detail" -f $ip 
    Uri = "http://{0}:8008/setup/eureka_info?options=detail&params=version,name,build_info,device_info,net,wifi,setup,settings,opt_in,opencast,multizone,audio,detail,night_mode_params,user_eq,room_equalizer" -f $ip 
    UserAgent = "curl"
}
irm @p -TimeoutSec 1
}


$range = 1..20

foreach ($i in $range) {
    $ip = Get-NetIPAddress -PrefixOrigin Dhcp | select -ExpandProperty ipaddress
    $ip = $ip -replace (".\d$",$i)
    Get-ChromeCastDevice -ip $ip -ErrorAction SilentlyContinue    
}
#https://github.com/balloob/pychromecast/blob/master/pychromecast/__init__.py

Sent from Mail for Windows 10


function Get-ChromeCastDeviceStatus {
    [CmdletBinding()]
    param($ip)
    $p = @{
        Method = "post"
        ContentType = "application/json" 
        Uri = "http://{0}:8008/setup/assistant/check_ready_status" -f $ip 
        UserAgent = "curl"
        Body = ConvertTo-Json @{"play_ready_message" = $false;"user_id"="118300704319639860919"}
    }
    irm @p -TimeoutSec 1
}

function Get-ChromeCastDeviceOffer {
    [CmdletBinding()]
    param($ip)
    $p = @{
        Method = "get"
        ContentType = "application/json" 
        Uri = "http://{0}:8008/setup/offer" -f $ip 
        UserAgent = "curl"
    }
    irm @p -TimeoutSec 1
}