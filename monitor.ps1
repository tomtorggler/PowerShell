# dot source the functions 

. ./MiningStats.ps1

function Get-MiningResults {

    $nh = Get-NiceHashResults -Address "1EWvQRiZ4yipsaQ7QwYs4WRhzAWrjvLHQf" | Select-Object -ExpandProperty result | Select-Object -ExpandProperty stats | Where-Object algo -eq 1
    $ltc = Get-LiteCoinResults -Key "d9fb6dfe4fb12d92e0af9b01a3a1fc21" | Select-Object -ExpandProperty user
    $xmr = Get-SupportXmrResults -Address "43wzHcx4W6qg6YtkvaSDPyW7bPpxB7Zmbfatv5GNuY797LmSBLeSxqtMWJ9PtMwaBpA5u9oRvCsATRSeJaUR5zQY2Cd34xy"
    $btc = Get-BitcoinComResults -Key "efdf8f3e-0e44-469c-b518-d2d24a99f516"

    $out = [ordered]@{
        "BTC" = $nh.balance
        "BCH" = $btc.bitcoinCashBalance
        "LTC" = $ltc.unpaid_rewards
        "XMR" = "0.$($xmr.amtDue)"
    }

    Write-Output (New-Object -TypeName psobject -Property $out) 
}

$s9stats = Get-AntMinerStats -ComputerName s91,s92 -Type S9
$l3stats = Get-AntMinerStats -ComputerName l31,l32 -Type l3

$out = $s9stats | Select-Object Host,Uptime,HashRate,Temp*,Fan*
$out += $l3stats | Select-Object Host,Uptime,HashRate,Temp*,Fan*
$out += Get-M01Stats

$outHw = $l3stats | Select-Object Host,Frequency,*Errors
$outHw += $s9stats | Select-Object Host,Frequency,*Errors

$outAsic = $l3stats | Select-Object Host,Frequency,*Status
$outAsic += $s9stats | Select-Object Host,Frequency,*Status

$mainTable = $out | ConvertTo-Html -Fragment
$unpaidTable = Get-MiningResults | ConvertTo-Html -Fragment -As List
$hardwareTable = $outHw | ConvertTo-Html -Fragment -As List
$asicTable = $outAsic | ConvertTo-Html -Fragment -As List

$index = ConvertTo-Html -CssUri "style.css" -Body "<h1>Mining Statistics</h1> $unpaidTable $mainTable <a href='hw.html'>Hardware</a>" -Title "Mining Statistics" -PostContent "<footer>Updated: $(get-date) by <a href='https://twitter.com/torggler' target='_blank'>@torggler</a></footer>" 
$index | Set-Content Set-Content index.html
$hardware = ConvertTo-Html -CssUri "style.css" -Body "<h1>Hardware Detail</h1> $hardwareTable <h1>ASIC Detail</h1>$asicTable" -Title "Mining Statistics" -PostContent "<footer>Updated: $(get-date) by <a href='index.html'>back</a></footer>" 
$hardware | Set-Content hw.html

cd tomtorggler.github.io
git add .
git commit -m "updates index"
git push
