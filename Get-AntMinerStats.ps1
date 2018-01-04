# A quick test to read AntMiner stats via the API

function Get-AntMinerStats {
    param(
        $ComputerName,
        $Port = 4028,
        [ValidateSet("S9","L3")]
        $Type
    )
    foreach ($miner in $ComputerName) {
        $StringData = (echo '{"command":"stats"}' | nc $miner $port).split(",").replace(":","=").replace('"','') | ConvertFrom-StringData 
    
        switch ($Type) {
            "S9" { 
                $out = [ordered]@{
                    "ComputerName" = $miner;
                    "Uptime" = [math]::round((New-TimeSpan -Seconds $($StringData.Where{$_.Keys -eq "Elapsed"}.Values)).TotalHours,2)
                    "GHS av" = $StringData.Where{$_.Keys -eq "GHS av"}.Values
                    "temp1" = $StringData.Where{$_.Keys -eq "temp2_6"}.Values
                    "temp2" = $StringData.Where{$_.Keys -eq "temp2_7"}.Values
                    "temp3" = $StringData.Where{$_.Keys -eq "temp2_8"}.Values                    
                    "temp_max" = $StringData.Where{$_.Keys -eq "temp_max"}.Values
                    "fan1" = $StringData.Where{$_.Keys -eq "fan3"}.Values
                    "fan2" = $StringData.Where{$_.Keys -eq "fan6"}.Values
                }
             }
            "L3" {
                $out = [ordered]@{
                    "ComputerName" = $miner;
                    "Uptime" = [math]::round((New-TimeSpan -Seconds $($StringData.Where{$_.Keys -eq "Elapsed"}.Values)).TotalHours,2)
                    "GHS av" = $StringData.Where{$_.Keys -eq "GHS av"}.Values
                    "temp1" = $StringData.Where{$_.Keys -eq "temp2_1"}.Values
                    "temp2" = $StringData.Where{$_.Keys -eq "temp2_2"}.Values
                    "temp3" = $StringData.Where{$_.Keys -eq "temp2_3"}.Values
                    "temp4" = $StringData.Where{$_.Keys -eq "temp2_4"}.Values
                    "temp_max" = $StringData.Where{$_.Keys -eq "temp_max"}.Values
                    "fan1" = $StringData.Where{$_.Keys -eq "fan1"}.Values
                    "fan2" = $StringData.Where{$_.Keys -eq "fan2"}.Values
                }
            }
        }
        Write-Output (New-Object -TypeName psobject -Property $out)
    }
}

function Get-M01Stats {
    param(
        $ComputerName = "10.0.0.157"
    )
    
    $(uptime ) -match "up (\d+\.\d+)" | Out-Null
    $uptime = $Matches[1]

    # kind of complicated
    #$sensors = sensors | Select-String -Pattern ":"
    #$sensorsTable = $sensors -replace ":","=" | ConvertFrom-StringData

    $out = @{
        "ComputerName" = $ComputerName;
        "Uptime" = $uptime;
        "GHS av" = Get-SupportXmrResults | Select-Object -ExpandProperty hash
    }
    Write-Output (New-Object -TypeName psobject -Property $out)
}


function Get-NiceHashResults {
    param(
        $Address = "1EWvQRiZ4yipsaQ7QwYs4WRhzAWrjvLHQf"
    )
    $uri = "https://api.nicehash.com/api?method=stats.provider&addr=$Address"
    Invoke-RestMethod -Uri $uri 
}

function Get-LiteCoinResults {
    param(
        $Key = "d9fb6dfe4fb12d92e0af9b01a3a1fc21"
    )
    $uri = "https://www.litecoinpool.org/api?api_key=$key"
    Invoke-RestMethod -Uri $uri 
}

function Get-SupportXmrResults {
    param (
        $Address = "43wzHcx4W6qg6YtkvaSDPyW7bPpxB7Zmbfatv5GNuY797LmSBLeSxqtMWJ9PtMwaBpA5u9oRvCsATRSeJaUR5zQY2Cd34xy"
    )
    $uri = "https://supportxmr.com/api/miner/$Address/stats"
    Invoke-RestMethod -Uri $uri 
}

function Get-MiningResults {

    $nh = Get-NiceHashResults | Select-Object -ExpandProperty result | Select-Object -ExpandProperty stats | Where-Object algo -eq 1
    $ltc = Get-LiteCoinResults | Select-Object -ExpandProperty user
    $xmr = Get-SupportXmrResults

    $out = @{
        "BTCUnpaid" = $nh.balance
        "LTCUnpaid" = $ltc.unpaid_rewards
        "XMRUnpaid" = "0.$($xmr.amtDue)"
    }

    Write-Output (New-Object -TypeName psobject -Property $out)
}

$out = Get-AntMinerStats -ComputerName 10.0.0.21,10.0.0.22 -Type l3
$out += Get-AntMinerStats -ComputerName 10.0.0.23,10.0.0.24 -Type S9
$out += Get-M01Stats

$out | ConvertTo-Html -Title "stats" -PreContent (Get-MiningResults | ConvertTo-Html -Fragment -As List) -PostContent "Updated: $(get-date)" | Set-Content tomtorggler.github.io/index.html

cd tomtorggler.github.io
git add .
git commit -m "updates index"
git push

