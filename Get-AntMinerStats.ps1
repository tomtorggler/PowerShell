# A quick test to read AntMiner stats via the API

function Get-AntMinerStats {
    param(
        $ComputerName,
        $Port = 4028
    )
    foreach ($miner in $ComputerName) {
        $out = (echo '{"command":"stats"}' | nc -v $miner $port).split(",").replace(":","=").replace('"','') | ConvertFrom-StringData | Where-Object {$_.Values -notlike "0" -and $_.Values -notlike "0.00"}
        $out += @{"ComputerName" = $miner}
        $out
    }
}

# Example Get-AntMinerStats -ComputerName "10.0.0.21","10.0.0.22","10.0.0.23","10.0.0.24"