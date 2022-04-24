
function round2($i){
    [math]::round($i,2)
}

function Get-KrakenStats {
    param(
        $Path,
        $Pair   
    )
    process {
        $items = import-csv -Path $path 
        if($Pair){
            $allPairs = $pair
        } else {
            $allPairs = ($items | Group-Object -Property pair).Name
        }
        foreach($pair in $allPairs){
            $out = [ordered]@{ pair='';pos='';vol='';cost='';fee='';maxprice='';minprice='';pnl='' }
            
            $pairItems = $items.where{$_.pair -eq $pair}
            $minmax = $pairItems | Measure-Object -Property price -Maximum -Minimum
            $buys  = $pairItems.where{$_.type -eq "buy"}
            $sells = $pairItems.where{$_.type -eq "sell"}
            $sumBuys  = round2(($buys.vol | Measure-Object -Sum).Sum)
            $sumSells = round2(($sells.vol | Measure-Object -Sum).sum)
            $costBuys  = round2(($buys.cost | Measure-Object -Sum).Sum)
            $costSells = round2(($sells.cost | Measure-Object -Sum).sum)
            $fee = round2(($pairItems | Measure-Object -Property fee -Sum).Sum)

            $out.pair = $pair
            $out.pos = $sumBuys - $sumSells
            $out.vol  = round2(($pairItems | Measure-Object -Property vol -sum).Sum)
            $out.cost = round2(($pairItems | Measure-Object -Property cost -sum).Sum)
            $out.fee = $fee
            $out.maxprice = round2($minmax.Maximum)
            $out.minprice = round2($minmax.Minimum)
            if($out.pos -eq 0){
                $out.pnl = round2($costSells - $costBuys - $fee)
            }
            
            [PSCustomObject]$out
        }
    }
}

Get-KrakenStats -Path ~/Downloads/trades.csv | ft

