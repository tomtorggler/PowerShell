
function ConvertTo-UnixTime {
    param(
        [Parameter(ValueFromPipeline)]
        [datetime]$Date = [datetime]::Now
    )
    process{
        [int]((New-TimeSpan -Start (Get-Date -Date '1970-01-01') -End (($Date).ToUniversalTime())).TotalSeconds)
    }
}

function New-NostrFilterString {
    [CmdletBinding()]
    param(
        [string[]]$ids,
        [string[]]$authors,
        [int[]]$kinds,
        [string]$etag,
        [string]$ptag,
        [int]$limit,
        [datetime]$since,
        [datetime]$until,
        $relay
    )
    $filters = [ordered]@{}
    switch($PSBoundParameters.Keys){
        'ids' {$filters.add('ids',$ids)}
        'authors' {$filters.add('authors',$authors)}
        'kinds' {$filters.add('kinds',$kinds)}
        'etag' {$filters.add('#e',$etag)}
        'ptag' {$filters.add('#p',$ptag)}
        'limit' {$filters.add('limit',$limit)}
        'since' {$filters.add('since',($since | ConvertTo-UnixTime))}
        'until' {$filters.add('until',($until | ConvertTo-UnixTime))}
    }
    $nosQ = @(
        "REQ",
        "nostrps",
        $filters
    )

    ConvertTo-Json -InputObject $nosQ -Compress
}

function New-NostrRelayConnection {
    [CmdletBinding()]
    param(
        $URL

    )
    $WS = New-Object System.Net.WebSockets.ClientWebSocket
    $CT = New-Object System.Threading.CancellationToken
    $WS.Options.UseDefaultCredentials = $true

    #Get connected
    $Conn = $WS.ConnectAsync($URL, $CT)
    While (!$Conn.IsCompleted) { 
        Start-Sleep -Milliseconds 100 
    }
    Write-Verbose "Connected to $($URL)"

    return $ws

}
function Send-NostrRequest {
    [CmdletBinding()]
    param(
        $WebSocket,
        $QueryString
    )
    
    $Command = [System.Text.Encoding]::UTF8.GetBytes($QueryString)
    $Send = New-Object System.ArraySegment[byte] -ArgumentList @(,$Command)            
    $CT = New-Object System.Threading.CancellationToken
    $Conn = $WebSocket.SendAsync($Send, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $CT)

    While (!$Conn.IsCompleted) {
        Start-Sleep -Milliseconds 100 
    }
    Write-Verbose "Sent Request $QueryString"

    return $conn
}

function Get-NostrEvent {
    [CmdletBinding()]
    param (
        [Parameter()]
        #[ValidateSet('wss://eden.nostr.land','wss://relay.snort.social','wss://relay.damus.io','wss://relay.nostr.info')]
        [string[]]$Relay = 'wss://eden.nostr.land',
        $Ids,
        $Kinds,
        $Authors,
        $Limit,
        $Since,
        $Until
    )
    begin {
        $filter = New-NostrFilterString @PSBoundParameters
    }
    process {
        foreach($rUri in $Relay){
            $ws = New-NostrRelayConnection -URL $rUri
            $send = Send-NostrRequest -QueryString $filter -WebSocket $ws 
            While ($WS.State -eq 'Open') {
                $Array = [byte[]] @(,0) * 1024    
                $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)
                $CT = New-Object System.Threading.CancellationToken
                $Conn = $WS.ReceiveAsync($Recv, $CT)
                While (!$Conn.IsCompleted) { 
                    Start-Sleep -Milliseconds 100 
                }
                $out = [System.Text.Encoding]::utf8.GetString($Recv.array)
                if($out -match '^\["EOSE"' ){
                    Write-Verbose "Received EOSE, closing connection."
                    $send = Send-NostrRequest -QueryString '["CLOSE", "nostrps"]' -WebSocket $ws
                    $ws.dispose()
                    $send.dispose()
                    $conn.dispose()
                    continue
                }
                try {
                    $outobj = $out | ConvertFrom-Json -ErrorAction stop -AsHashtable | Where-Object {$_ -is [hashtable]}
                    $outobj.created_at = Get-Date -UnixTimeSeconds $outobj.created_at
                    $outobj.add('Relay',$rUri)
                    new-object -TypeName psobject -Property $outobj
                } catch {
                    # "could not convert from json"
                }
            }
        }
    }
}


$relays = @(
    'wss://nostr.milou.lol',
    'wss://bitcoiner.social',
    'wss://relay.nostr.com.au',
    'wss://relay.nostrati.com',
    'wss://nostr.inosta.cc',
    'wss://nostr.plebchain.org',
    'wss://atlas.nostr.land',
    'wss://relay.nostrich.land',
    'wss://relay.nostriches.org',
    'wss://private.red.gb.net',
    'wss://nostr.decentony.com',
    'wss://relay.orangepill.dev',
    'wss://puravida.nostr.land',
    'wss://nostr.wine',
    'wss://eden.nostr.land',
    'wss://nostr.gives.africa',
    'wss://relay.snort.social',
    'wss://relay.damus.io'
) 

function Get-NostrRelayInfo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $uri
    )
    process {
        write-verbose "testing $uri"
        $uri = $uri -replace '^ws','http'
        $out = [ordered]@{
            relay = $uri
        }  
        $out.time = (Measure-Command {$r=Invoke-RestMethod -TimeoutSec 2 $uri -Headers @{accept='application/nostr+json'} -ErrorAction SilentlyContinue }).TotalMilliseconds
        $out.nips = $r.supported_nips -join ', '
        $out.software = $r.software
        $out.version = $r.version
        $out.pubkey = $r.pubkey
        [pscustomobject]$out
    }
}

#$relays | Get-NostrRelayInfo