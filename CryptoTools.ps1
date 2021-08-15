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

enum CryptoCurrencySymbol {
    eth
    btc
    ltc
    bch
}

class CryptoCurrency {
    [string]$address
}

class ETH : CryptoCurrency {
    ETH ($obj) {
        $this.address = $obj.address
        $this.balance = $obj.balance / 1000000000000000000
        $this.sent = $obj.total_sent / 1000000000000000000
        $this.received = $obj.total_received / 1000000000000000000
    }
    [double]$balance
    [double]$sent
    [double]$received
}

class BTC : CryptoCurrency {
    BTC ($obj) {
        $this.address = $obj.address
        $this.balance = $obj.balance / 100000000
        $this.sent = $obj.total_sent / 100000000
        $this.received = $obj.total_received / 100000000
    }
    [double]$balance
    [double]$sent
    [double]$received
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
        $Version = "v1"
    )
    $Currency = Get-CurrencyFromAddress -Address $Address
    $Address = $Address.Replace("0x","")
    Write-Verbose "Currency is $Currency"
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
        $Version = "v1"
    )
    $Currency = Get-CurrencyFromAddress -Address $Address
    $Address = $Address.Replace("0x","")
    Write-Verbose "Currency is $Currency"
    $r = Invoke-RestMethod https://api.blockcypher.com/$version/$currency/main/addrs/$Address/balance
    if ($r) {
        switch($Currency) {
            "eth" {
                [ETH]::new($r)
            }
            Default {
                [BTC]::new($r)
            }
        }
    }
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
        [Parameter(ParameterSetName="ByTxHash")]
        [CryptoCurrencySymbol]
        $Currency = "eth"
    )

    # provide two possibilites of using the function, 
    # either get a specific tx by hash or get all tx for a certain address

    if($Hash) {
        $hash = $hash.Replace("^0x","")
        Invoke-RestMethod https://api.blockcypher.com/$version/$currency/main/txs/$Hash
    } elseif ($Address) {
        Get-BlockCypherAddress -Address $Address | Select-Object -ExpandProperty txrefs
    }
}

function Get-CurrencyFromAddress {
    [CmdletBinding()]
    param($Address)
    switch ($Address) {
        { $_ -match "^[13][a-zA-Z0-9]{27,34}$" } { "btc" }
        { $_ -match "^L[a-km-zA-HJ-NP-Z1-9]{26,33}$" } { "ltc" }
        { $_ -match "^(0x)?[0-9a-f]{40}$" } { "eth" }
    }
}


function Get-BchBalance {
    [CmdletBinding()]
    param(
        $Address
    )

    $result = Invoke-RestMethod "https://api.blockchair.com/bitcoin-cash/dashboards/address/$address"
    if($result){
        $result.data
    }

}

function Get-BchTransaction {
    [CmdletBinding()]
    param(
        $Hash
    )
    $result = Invoke-RestMethod "https://api.blockchair.com/bitcoin-cash/transactions?q=hash($hash)"
    if($result){
        $result.data
    }
}


#https://explorer.bitcoin.com/api/btc/addr/14hbuMuFCGSCzQr3TCVqPUKGkDGbepEoe2
#https://explorer.bitcoin.com/api/bch/txs/?address=14hbuMuFCGSCzQr3TCVqPUKGkDGbepEoe2
#https://explorer.bitcoin.com/api/bch/txs/?hash=ffe712907e11479bdca14445f66b5fbabd4a5e2c73bc7d7f1511429a470be036


function Get-ChainfeedTx {
    [CmdletBinding()]
    param (
        [string]
        $Hash
    )
    process {
        $Response = Invoke-RestMethod https://chainfeed.org/tx/$Hash
        New-Object -TypeName psobject -Property (@{
            Sender = $Response.Sender
            Text = [System.Text.Encoding]::ASCII.GetString($Response.data[-1].buf.data)
        })
    }
}



function get-unixtime {
    param([datetime]$date)
    if(-not $date) {
        $date = ([datetime]::UtcNow).AddHours(-1)
    }
    $ts = New-TimeSpan -Start (Get-Date 01.01.1970) -End $date
    [int]$ts.TotalSeconds
}
function invoke-whalealertapi {
    param(
        $endpoint = "status",
        $apikey = $whalealertapi,
        $baseUrl = "https://api.whale-alert.io/v1",
        $currency,
        $minvalue,
        $start = (get-unixtime)
    )
    $header = @{
        "X-WA-API-KEY" = $apikey
    }
    $uri = $baseUrl,$endpoint -join "/"
    $uri += "?start=$start"
    if($currency){
        $uri += "&currency=$currency"
    }
    if($minvalue){
        $uri += "&min_value=$minvalue"
    }
    $r = Invoke-RestMethod -Uri $uri -Headers $header
    $r.transactions
}
