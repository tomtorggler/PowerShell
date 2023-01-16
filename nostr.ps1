
function New-NostrFilterString {
    [CmdletBinding()]
    param(
        [string[]]$ids,
        [string[]]$authors,
        [int[]]$kinds,
        [string]$etag,
        [string]$ptag,
        [int]$limit,
        $relay
    )
    $nosQ = @(
        "REQ",
        "nostrps"
    )
    switch($PSBoundParameters.Keys){
        'ids' {$nosQ += @{ids=$ids}}
        'authors' {$nosQ += @{authors=$authors}}
        'kinds' {$nosQ += @{kinds=$kinds}}
        'etag' {$nosQ += @{'#e'=$etag}}
        'ptag' {$nosQ += @{'#p'=$ptag}}
        'limit' {$nosQ += @{'limit'=$limit}}
    }
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
        [ValidateSet('wss://nostr.v0l.io','wss://relay.snort.social','wss://relay.damus.io','wss://relay.nostr.info')]
        [string[]]$Relay = 'wss://nostr.v0l.io',
        $Ids,
        $Kinds = 1,
        $Authors,
        $Limit
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
                    # could not convert from json
                }
            }
        }
    }
}



Get-NostrEvent -Kinds 3 -Relay wss://nostr.v0l.io,wss://relay.nostr.info -Verbose 