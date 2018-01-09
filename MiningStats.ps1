# A quick test to read AntMiner stats via API
# ... and more quick stuff to gather pool data 

function Get-AntMinerStats {
    param(
        $ComputerName,
        $Port = 4028,
        [ValidateSet("S9","L3")]
        $Type
    )
    foreach ($miner in $ComputerName) {
        $StringData = (echo '{"command":"stats"}' | nc $miner $port).split(",").replace(":","=").replace('"','') | ConvertFrom-StringData
        
        $out = [ordered]@{
            "Host" = $miner
            "Uptime" = [math]::round((New-TimeSpan -Seconds $($StringData.Where{$_.Keys -eq "Elapsed"}.Values)).TotalHours,2)
            "HashRate" = $StringData.Where{$_.Keys -eq "GHS av"}.Values
            "Frequency" = $StringData.Where{$_.Keys -eq "Frequency"}.Values          
        }
    
        switch ($Type) {
            "S9" { 
                foreach ($i in 6..8) {
                    $out.Add("Temp$($i-5)",$StringData.Where{$_.Keys -eq "temp2_$i"}.Values)
                    $out.add("ASIC $i Status",$StringData.Where{$_.Keys -eq "chain_acs$i"}.Values)    
                    $out.add("ASIC $i Errors",$StringData.Where{$_.Keys -eq "chain_hw$i"}.Values)  
                }
                $out.Add("Fan 1",$StringData.Where{$_.Keys -eq "fan3"}.Values)
                $out.Add("Fan 2",$StringData.Where{$_.Keys -eq "fan6"}.Values)
            }
            "L3" {
                foreach ($i in 1..4) {
                    $out.add("Temp$i",$StringData.Where{$_.Keys -eq "temp2_$i"}.Values)
                    $out.add("ASIC $i Status",$StringData.Where{$_.Keys -eq "chain_acs$i"}.Values)    
                    $out.add("ASIC $i Errors",$StringData.Where{$_.Keys -eq "chain_hw$i"}.Values)
                }
                $out.add("Fan 1",$StringData.Where{$_.Keys -eq "fan1"}.Values)
                $out.add("Fan 2",$StringData.Where{$_.Keys -eq "fan2"}.Values)
            }
        }
        Write-Output (New-Object -TypeName psobject -Property $out) 
    }
}

function Get-M01Stats {
    param(
        $ComputerName = "m01"
    )
    
    # kind of complicated
    #$sensors = sensors | Select-String -Pattern ":"
    #$sensorsTable = $sensors -replace ":","=" | ConvertFrom-StringData

    $out = @{
        "Host" = $ComputerName;
        "Uptime" = [math]::Round((New-TimeSpan -Start (uptime -s) -End (get-date)).TotalHours,2);
        "HashRate" = Invoke-RestMethod -uri "http://$ComputerName`:16000/api.json" | Select-Object -ExpandProperty hashrate | Select-Object -ExpandProperty total | Select-Object -First 1
    }
    Write-Output (New-Object -TypeName psobject -Property $out)
}

function Get-NiceHashResults {
    param(
        $Address
    )
    $uri = "https://api.nicehash.com/api?method=stats.provider&addr=$Address"
    Invoke-RestMethod -Uri $uri 
}

function Get-LiteCoinResults {
    param(
        $Key
    )
    $uri = "https://www.litecoinpool.org/api?api_key=$key"
    Invoke-RestMethod -Uri $uri 
}

function Get-SupportXmrResults {
    param (
        $Address
    )
    $uri = "https://supportxmr.com/api/miner/$Address/stats"
    Invoke-RestMethod -Uri $uri 
}

function Get-BitcoinComResults {
    param(
        $Key
    )
    $UserUri = "https://console.pool.bitcoin.com/srv/api/user?apikey=$Key"
    #$WorkerUri = "https://console.pool.bitcoin.com/srv/api/workers?apikey=$Key" 
    Invoke-RestMethod -Uri $UserUri
    #Invoke-RestMethod -Uri $WorkerUri   
}


