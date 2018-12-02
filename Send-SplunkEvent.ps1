<#PSScriptInfo

.VERSION 1.0.0

.GUID a7d9b0b5-0f81-4ec7-be89-7c6a0390ef50

.AUTHOR @torggler

.TAGS Splunk

.PROJECTURI https://ntsystems.it/post/sending-events-to-splunks-http-event-collector-with-powershell/

#>

<#
.SYNOPSIS
    Send events to Splunk's HTTP Event Collector. 
.DESCRIPTION
    This function uses Invoke-RestMethod to send structured data to Splunk HTTP Event Collector. Use the 
    HostName and DateTime parameters to control Splunk's 'host' and 'time' properties for the generated event.
.EXAMPLE
    PS C:\> .\Send-SplunkEvent.ps1 -InputObject @{message="Hello Splunk!"} -Key <token>
    
    This example sends a simple event containing "message": "Hello Splunk!" to the event collector running on the local system.
.EXAMPLE
    PS C:\> Import-Csv logs.csv | .\Send-SplunkEvent -Key <token> -HostName SBC1 -Uri "https://splunk01.example.com:8088/services/collector"
    
    This example imports logs from a CSV file and sends each one of them to event collector running on splunk01.example.com.
    The HostName parameter specifies which host created the logs.   
.INPUTS
    [psobject]
.OUTPUTS
    None.
.NOTES
    Author: @torggler
.LINK
   https://ntsystems.it/PowerShell/Send-SplunkEvent/
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    # Data object that will be sent to Splunk's HTTP Event Collector.
    [Parameter(Mandatory,ValueFromPipeline)]
    $InputObject,
    
    # HostName to be used for Splunk's 'host' property. Default's to name of the local system.
    [Parameter()]
    [string]
    $HostName = (hostname),

    # Date and Time of the event. Defaults to now() on the local system.
    [Parameter()]
    [System.DateTime]
    $DateTime = (Get-Date),
    
    # URI of the Splunk HTTP Event Collector instance.
    [Parameter()]
    [string]
    $Uri = "http://localhost:8088/services/collector",
    
    # Key for the Splunk HTTP Event Collector instance.
    [Parameter()]
    [string]
    $Key
)
process {
    # Splunk events can have a 'time' property in epoch time. If it's not set, use current system time.
    $unixEpochStart = New-Object -TypeName DateTime -ArgumentList 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    $unixEpochTime = [int]($DateTime.ToUniversalTime() - $unixEpochStart).TotalSeconds
    # Create json object to send 
    $Body = ConvertTo-Json -InputObject @{event=$InputObject; host=$HostName; time=$unixEpochTime} -Compress
    Write-Verbose "Sending $Body to $Uri"
    if($PSCmdlet.ShouldProcess($Body,"Send")) {
        # Only return if something went wrong, i.e. http response is not "success"
        $r = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization="Splunk $Key"} -Body $Body
        if($r.text -ne "Success") {$r} 
    }
}
