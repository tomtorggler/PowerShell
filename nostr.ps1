
function New-NostrFilterString {
    [CmdletBinding()]
    param(
        [string[]]$ids,
        [string[]]$authors,
        [int[]]$kinds,
        [string]$etag,
        [string]$ptag
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

$ws = New-NostrRelayConnection -URL wss://relay.damus.io

$filter = New-NostrFilterString -kinds 1

$send = Send-NostrRequest -QueryString $filter -WebSocket $ws -verbose

While ($WS.State -eq 'Open') {
    $Array = [byte[]] @(,0) * 1024    
    $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)
    $CT = New-Object System.Threading.CancellationToken
    $Conn = $WS.ReceiveAsync($Recv, $CT)
    While (!$Conn.IsCompleted) { 
        Start-Sleep -Milliseconds 200 
    }
    $out = [System.Text.Encoding]::utf8.GetString($Recv.array)
    
    try {
        $out | ConvertFrom-Json -ErrorAction stop -OutVariable global:outobj -AsHashtable
        $global:outarray += $global:outobj
    } catch {
        #"could not convert $out"
    }
}