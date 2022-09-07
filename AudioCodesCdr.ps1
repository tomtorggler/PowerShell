
function Get-Cdr {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]
        $Path,
        [Parameter(Mandatory)]
        [ValidateSet("MEDIA","SBC")]
        [string]$Type
    )
    process {
        $Pattern = "\|CALL_[START|CONNECT|END]"
        if($type -eq "MEDIA") { 
            $Pattern = "\|MEDIA_[START|UPDATE|END]" 
        } 
        if(Test-Path $Path) {
            Write-Verbose "Get CDR from: $Path"
            (Select-String -Pattern $Pattern -Path $Path | Select-Object -ExpandProperty line).TrimEnd() -replace "\|","," -replace "\s*,","," -replace "BYE(.*)","BYE" -replace "CANCEL(.*)","CANCEL" -replace "q.850(.*)","Q.850"
        }   
    }
}

function Split-Cdr {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]
        $Path,
        [System.IO.FileInfo]
        $OutputFolder = $env:temp
    )
    # create output folder if it does not exist
    New-Item -Path $OutputFolder -ItemType Directory -ErrorAction SilentlyContinue
    $MediaPath = Join-path -Path $OutputFolder -ChildPath media.txt
    $SBCPath = Join-path -Path $OutputFolder -ChildPath sbc.txt
    # delete existing target files if they exist
    Remove-Item $MediaPath,$SBCPath -ErrorAction SilentlyContinue
    foreach($f in $path) {
        Get-Cdr -Path $f -Type SBC | Add-Content $SBCPath
        Get-Cdr -Path $f -Type MEDIA | Add-Content $MediaPath
    }
}

function Import-Cdr {
    <#
    .SYNOPSIS
        Import CDR from file.
    .DESCRIPTION
        This function uses Import-Csv to import CDR information form a file. 
    .EXAMPLE
        PS C:\> Import-Cdr -Path .\CDR-2018-10-03-08.log -Header $Header
        This example imports Media CDRs.
    .INPUTS
        [system.io.fileinfo]
    .OUTPUTS
        [psobject]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]
        $Path,
        [Parameter()]
        [string[]]$Header 
    )
    process {
        if(Test-Path $Path) {
            Import-Csv -Path $Path -Delimiter "," -Header $Header | Select-Object *,@{n="Jitter";e={$_.RTPjitter -as [int]}},@{n="Delay";e={$_.RTPdelay -as [int]}} -ExcludeProperty RTPjitter,RTPdelay
        }
    }
}


function Get-CdrTitle {
    <#
    .SYNOPSIS
        Extract CSV header from CDR file.
    .DESCRIPTION
        This function extracts the header information from a CDR file. This can later be used, to import the CDR using Import-Csv. 
    .EXAMPLE
        PS C:\> Get-CdrTitle .\CDR-2018-10-03-08.log -Type SBC
        This example extracts the header for SBCReport.
    .EXAMPLE
        PS C:\> Get-CdrTitle .\CDR-2018-10-03-08.log -Type MEDIA
        This example extracts the header for MediaReport.
    .INPUTS
        [system.io.fileinfo]
    .OUTPUTS
        [string]
    .NOTES
        Author: @torggler
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]
        $Path,
        [Parameter(Mandatory)]
        [ValidateSet("MEDIA","SBC","GW")]
        [string]$Type
    )
    switch ($type) {
        'media' { $Pattern = "MediaReportType" }
        'gw' { $Pattern = "GWReportType" }
        'sbc' { $Pattern = "SBCReportType" }
    }
    
    if(Test-Path $Path) {
        #$title = Select-String -Path $path -Pattern $Pattern | Select-Object -ExpandProperty line | Select-Object -First 1
        #$out = $title -replace "^.*?\|","Timestamp|" -replace " ","" -split "\|" -replace "\(\w+\)","" -replace $Pattern,"ReportType"
    }
    if($Type -eq "MEDIA" -and -not($out)){
        $out = @('Timestamp','ReportType','SIPCallId','SessionId','Cid','MediaType','Coder','Intrv','LocalRtpIp','LocalRtpPort','RemoteRtpIp','RemoteRtpPort','InPackets','OutPackets','LocalPackLoss','RemotePackLoss','RTPdelay','RTPjitter','TxRTPssrc','RxRTPssrc','LocalRFactor','RemoteRFactor','LocalMosCQ','RemoteMosCQ','TxRTPIPDiffServ','LatchedRtpIp','LatchedRtpPort','LatchedT38Ip','LatchedT38Port','CoderTranscoding','LegId')
    } elseif($Type -eq "SBC" -and -not($out)) {
        $out = @('Timestamp','ReportType','EPTyp','SIPCallId','SessionId','Orig','SourceIp','SourcePort','DestIp','DestPort','TransportType','SrcURI','SrcURIBeforeMap','DstURI','DstURIBeforeMap','Durat','TrmSd','TrmReason','TrmReasonCategory','SetupTime','ConnectTime','ReleaseTime','RedirectReason','RedirectURINum','RedirectURINumBeforeMap','TxSigIPDiffServ','IPGroup','SrdId','SIPInterfaceId','ProxySetId','IpProfileId','MediaRealmId','DirectMedia','SIPTrmReason','SipTermDesc')
    } elseif ($Type -eq "GW" -and -not($out)) {
        $out = @('Timestamp','ReportType','Cid','SessionId','LegId','Trunk','BChan','ConId','TG','EPTyp','Orig','SourceIp','DestIp','SrcTON','SrcNPI','SrcPhoneNum','SrcNumBeforeMap','DstTON','DstNPI','DstPhoneNum','DstNumBeforeMap','Duration','Coder','Intrv','RtpIp','Port','TrmSd','TrmReason','Fax','InPackets','OutPackets','PackLoss','RemotePackLoss','SIPCallId','SetupTime','ConnectTime','ReleaseTime','RTPdelay','RTPjitter','RTPssrc','RemoteRTPssrc','RedirectReason','TON','NPI','RedirectPhonNum','MeteringPulses','SrcHost','SrcHostBeforeMap','DstHost','DstHostBeforeMap','IPG (name)','LocalRtpIp','LocalRtpPort','Amount','Mult','TrmReasonCategory','RedirectNumBeforeMap','SrdId (name)','SIPInterfaceId (name)','ProxySetId (name)','IpProfileId (name)','MediaRealmId (name)','SigTransportType','TxRTPIPDiffServ','TxSigIPDiffServ','LocalRFactor','RemoteRFactor','LocalMosCQ','RemoteMosCQ','SigSourcePort','SigDestPort','MediaType','AMD','Percent','SIPTrmReason','SIPTer')
    }
    Write-Output $out
}


<#
function Get-BadStream {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $Path,
        [Parameter()]
        [ValidateSet("Jitter","Delay","PackLoss")]
        $Type = "Jitter",
        [int]
        $Count
    )
    process {
        switch($Type){
            'Jitter' { $fs = {$_.RTPjitter -gt 1} }
            'Delay' { $fs = {$_.RTPdelay -gt 1} }
            'PackLoss' { $fs = {$_.RemotePackLoss -gt 1 -or $_.LocalPackLoss -gt 1}}
        }
        if($count) {
            ### Add Header!
            Import-Cdr -Path $Path | Where-Object -FilterScript $fs | Select-Object -First $Count
        } else {
            Import-Cdr -Path $Path | Where-Object -FilterScript $fs
        }
        
    }    
}
#>

function Get-NrFromUri {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach($i in $InputObject) {
            $i -replace "[@|;].*$",""
        }
    }
}

function Get-DateFromTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $InputObject
    )
    process {
        foreach($i in $InputObject) {
            $J = $i -split "UTC"
            Get-Date (($J[1] -replace "(\w{3})(\w{3})(\d{2})(\d{4})","`$1 `$2 `$3 `$4"),$J[0] -join " ")
        }
    }
}

function Get-HostFromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]
        $InputObject
    )
    process {
        # split the Path at \ and try to cast each part as [ipaddress]. Only returns valid casts.
        $InputObject.DirectoryName -split "\\" | ForEach-Object { $_ -as [ipaddress] } | Select-Object -ExpandProperty IPAddressToString
    }
}

function Get-MediaCdr {
    [cmdletbinding()]
    param($path)
    $header = Get-CdrTitle -Path $path -Type MEDIA
    $tempfile = Join-path -Path $env:temp -ChildPath "$((get-date).ticks).txt"
    Get-Cdr $path -Type MEDIA | Set-Content $tempfile
    Import-Cdr -Header $header -Path $tempfile
}

function Get-SbcCdr {
    [cmdletbinding()]
    param($path)
    $header = Get-CdrTitle -Path $path -Type SBC
    $tempfile = Join-path -Path $env:temp -ChildPath "$((get-date).ticks).txt"
    Get-Cdr $path -Type SBC | Set-Content $tempfile
    Import-Cdr -Header $header -Path $tempfile
}

function Get-GWCdr {
    [cmdletbinding()]
    param($path)
    $header = Get-CdrTitle -Path $path -Type gw
    $tempfile = Join-path -Path $env:temp -ChildPath "$((get-date).ticks).txt"
    Get-Cdr $path -Type sbc | Set-Content $tempfile
    Import-Cdr -Header $header -Path $tempfile
}
