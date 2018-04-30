function Convert-BchAddress {
    <#
    .SYNOPSIS
        Converts Bitcoin Cash Address formats. 
    .DESCRIPTION
        This function uses https://cashaddr.bitcoincash.org to convert Bitcoin Cash address formats. It supports legacy and bitcoincash: address formats.
        The outout is a custom object containing all address formats and links to block explorers to for convenience. 
    .EXAMPLE
        PS C:\> Convert-BchAddress -Address "1BppmEwfuWCB3mbGqah2YuQZEZQGK3MfWc"
        
        This example converts a legacy address to the new bitcoincash format.
    .EXAMPLE
        PS C:\> Convert-BchAddress -Address "bitcoincash:qpmtetdtqpy5yhflnmmv8s35gkqfdnfdtywdqvue4p"
        
        This example converts a new address to the legacy format.
    .INPUTS
        [string]
    .OUTPUTS
        [PSCustomObject]
    .NOTES
        More information: https://www.bitcoinabc.org/cashaddr 
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        $Address
    )
    $uri = "https://cashaddr.bitcoincash.org/convert?address=$Address"
    try {
        $out = Invoke-RestMethod -Uri $uri -ErrorAction Stop
    } catch {
        Write-Warning "Could not connect."
    }
    $out | Add-Member -MemberType NoteProperty -Name "Blockchair" -Value "https://blockchair.com/bitcoin-cash/address/$($out.cashaddr.replace(":","%3A"))"
    $out | Add-Member -MemberType NoteProperty -Name "Blockdozer" -Value "https://blockdozer.com/address/$($out.cashaddr.replace(":","%3A"))"
    Write-Output $out
}

enum BNBSymbol {
    # update with
    # (irm https://api.binance.com/api/v1/exchangeInfo | select -ExpandProperty symbols | select -ExpandProperty symbol) -join "; "
    ETHBTC; LTCBTC; BNBBTC; NEOBTC; QTUMETH; EOSETH; SNTETH; BNTETH; BCCBTC; GASBTC; BNBETH; BTCUSDT; ETHUSDT; HSRBTC; OAXETH; DNTETH; MCOETH; ICNETH; MCOBTC; WTCBTC; WTCETH; LRCBTC; LRCETH; QTUMBTC; YOYOBTC; OMGBTC; OMGETH; ZRXBTC; ZRXETH; STRATBTC; STRATETH; SNGLSBTC; SNGLSETH; BQXBTC; BQXETH; KNCBTC; KNCETH; FUNBTC; FUNETH; SNMBTC; SNMETH; NEOETH; IOTABTC; IOTAETH; LINKBTC; LINKETH; XVGBTC; XVGETH; SALTBTC; SALTETH; MDABTC; MDAETH; MTLBTC; MTLETH; SUBBTC; SUBETH; EOSBTC; SNTBTC; ETCETH; ETCBTC; MTHBTC; MTHETH; ENGBTC; ENGETH; DNTBTC; ZECBTC; ZECETH; BNTBTC; ASTBTC; ASTETH; DASHBTC; DASHETH; OAXBTC; ICNBTC; BTGBTC; BTGETH; EVXBTC; EVXETH; REQBTC; REQETH; VIBBTC; VIBETH; HSRETH; TRXBTC; TRXETH; POWRBTC; POWRETH; ARKBTC; ARKETH; YOYOETH; XRPBTC; XRPETH; MODBTC; MODETH; ENJBTC; ENJETH; STORJBTC; STORJETH; BNBUSDT; VENBNB; YOYOBNB; POWRBNB; VENBTC; VENETH; KMDBTC; KMDETH; NULSBNB; RCNBTC; RCNETH; RCNBNB; NULSBTC; NULSETH; RDNBTC; RDNETH; RDNBNB; XMRBTC; XMRETH; DLTBNB; WTCBNB; DLTBTC; DLTETH; AMBBTC; AMBETH; AMBBNB; BCCETH; BCCUSDT; BCCBNB; BATBTC; BATETH; BATBNB; BCPTBTC; BCPTETH; BCPTBNB; ARNBTC; ARNETH; GVTBTC; GVTETH; CDTBTC; CDTETH; GXSBTC; GXSETH; NEOUSDT; NEOBNB; POEBTC; POEETH; QSPBTC; QSPETH; QSPBNB; BTSBTC; BTSETH; BTSBNB; XZCBTC; XZCETH; XZCBNB; LSKBTC; LSKETH; LSKBNB; TNTBTC; TNTETH; FUELBTC; FUELETH; MANABTC; MANAETH; BCDBTC; BCDETH; DGDBTC; DGDETH; IOTABNB; ADXBTC; ADXETH; ADXBNB; ADABTC; ADAETH; PPTBTC; PPTETH; CMTBTC; CMTETH; CMTBNB; XLMBTC; XLMETH; XLMBNB; CNDBTC; CNDETH; CNDBNB; LENDBTC; LENDETH; WABIBTC; WABIETH; WABIBNB; LTCETH; LTCUSDT; LTCBNB; TNBBTC; TNBETH; WAVESBTC; WAVESETH; WAVESBNB; GTOBTC; GTOETH; GTOBNB; ICXBTC; ICXETH; ICXBNB; OSTBTC; OSTETH; OSTBNB; ELFBTC; ELFETH; AIONBTC; AIONETH; AIONBNB; NEBLBTC; NEBLETH; NEBLBNB; BRDBTC; BRDETH; BRDBNB; MCOBNB; EDOBTC; EDOETH; WINGSBTC; WINGSETH; NAVBTC; NAVETH; NAVBNB; LUNBTC; LUNETH; TRIGBTC; TRIGETH; TRIGBNB; APPCBTC; APPCETH; APPCBNB; VIBEBTC; VIBEETH; RLCBTC; RLCETH; RLCBNB; INSBTC; INSETH; PIVXBTC; PIVXETH; PIVXBNB; IOSTBTC; IOSTETH; CHATBTC; CHATETH; STEEMBTC; STEEMETH; STEEMBNB; NANOBTC; NANOETH; NANOBNB; VIABTC; VIAETH; VIABNB; BLZBTC; BLZETH; BLZBNB; AEBTC; AEETH; AEBNB; RPXBTC; RPXETH; RPXBNB; NCASHBTC; NCASHETH; NCASHBNB; POABTC; POAETH; POABNB; ZILBTC; ZILETH; ZILBNB; ONTBTC; ONTETH; ONTBNB; STORMBTC; STORMETH; STORMBNB; QTUMBNB; QTUMUSDT; XEMBTC; XEMETH; XEMBNB; WANBTC; WANETH; WANBNB; WPRBTC; WPRETH; QLCBTC; QLCETH; SYSBTC; SYSETH; SYSBNB; QLCBNB; GRSBTC; GRSETH; ADAUSDT; ADABNB; CLOAKBTC; CLOAKETH; GNTBTC; GNTETH; GNTBNB
}


class BNBTicker {

    BNBTicker($obj) {
        $this.Symbol = $obj.symbol
        $this.PercentChange = $obj.pricechangepercent
        $this.LastPrice = $obj.lastprice
        $this.Open = ConvertFrom-BNBTime($obj.openTime)
    }

    [void]FromBNBTime ($MilliSeconds) {
        $this.Open = ConvertFrom-BNBTime($MilliSeconds)
    }

    [BNBSymbol]$Symbol
    [single]$PercentChange
    [string]$LastPrice
    [datetime]$Open
}

function Get-BinanceTicker {
    [cmdletbinding()]
    param(
        # Specify the currency pair (symbol) for which to get the price.
        [BNBSymbol[]]
        $Symbol
    )
    process {
        foreach($s in $Symbol){
            $result = Invoke-RestMethod -Uri https://api.binance.com/api/v1/ticker/24hr?symbol=$s -ErrorAction SilentlyContinue 
            #| Select-Object -Property symbol,pricechangepercent,lastprice,openTime
            if($result){
                [BNBTicker]::new($result)
            }
        }   
    }
}

function ConvertFrom-BNBTime ($MilliSeconds) {
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1970-01-01').AddMilliSeconds($MilliSeconds))
}


enum CryptoCurrency {
    eth
    btc
    ltc
}

function Get-BlockCypherAddress {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true, 
            Position=0
        )]
        [string]
        $Address,
        [string]
        $Version = "v1",
        [CryptoCurrency]
        $Currency = "eth"
    )

    $Address = $Address.Replace("0x","")

    Invoke-RestMethod https://api.blockcypher.com/$version/$currency/main/addrs/$Address
}

function Get-BlockCypherBalance {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true, 
            Position=0
        )]
        [string]
        $Address,
        [string]
        $Version = "v1",
        [CryptoCurrency]
        $Currency = "eth"
    )
    $Address = $Address.Replace("0x","")
    Invoke-RestMethod https://api.blockcypher.com/$version/$currency/main/addrs/$Address/balance
}

function Get-BlockCypherTransaction {
    [CmdletBinding(DefaultParameterSetName="ByTxHash")]
    param(
        [Parameter(
            Position=0,
            ParameterSetName="ByTxHash",
            Mandatory=$True
        )]
        [string]
        $Hash,
        [Parameter(
            ParameterSetName="ByAddress",
            Mandatory=$True
        )]
        [string]
        $Address,
        [string]
        $Version = "v1",
        [CryptoCurrency]
        $Currency = "eth"
    )

    # provide two possibilites of using the function, 
    # either get a specific tx by hash or get all tx for a certain address

    if($Hash) {
        $hash = $hash.Replace("^0x","")
        Invoke-RestMethod https://api.blockcypher.com/$version/$currency/main/txs/$Hash
    } elseif ($Address) {
        $Address = $Address.Replace("0x","")
        Get-BlockCypherAddress -Address $Address -Currency $PSBoundParameters.Currency | Select-Object -ExpandProperty txrefs
    }
}

