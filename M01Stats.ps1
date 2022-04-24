function Get-M01Stats {
    param(
        $ComputerName = "m01"
    )
    
    # kind of complicated
    #$sensors = sensors | Select-String -Pattern ":"
    #$sensorsTable = $sensors -replace ":","=" | ConvertFrom-StringData

    try {
        $xmrApi = Invoke-RestMethod -uri "http://$ComputerName`:16000/api.json" -ErrorAction Stop
        $hashrate = $xmrApi | Select-Object -ExpandProperty hashrate | Select-Object -ExpandProperty total | Select-Object -First 1
    } catch {
        Write-Warning "Could not connect to XMR Api"
    }

    $out = [ordered]@{
        "TimeStamp" = $(get-date -Format "yyyy-MM-dd HH:mm:ss")
        "Host" = $ComputerName;
        "Uptime" = $xmrApi.uptime
        "HashRate" = $hashrate
    }
    Write-Output (New-Object -TypeName psobject -Property $out)
}