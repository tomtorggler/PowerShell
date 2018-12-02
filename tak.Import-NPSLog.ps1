function Import-NPSLog {
    <#
    .SYNOPSIS
    Import Network Policy Server log files.
    
    .DESCRIPTION
    This function uses Import-Csv to import Network Policy Server logfiles. It adds the header information in order 
    to create usable objects. 
    
    .PARAMETER Path
    Path to the log files.
    
    .PARAMETER Delimiter
    Delimiter as used by Impor-Csv.
    
    .PARAMETER Filter
    Specify a filter to use when retreiving log files.

    .PARAMETER Age
    Specify the number of days to be included.
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [System.IO.FileInfo]
        $Path = "C:\Windows\System32\LogFiles",
        [string]
        $Delimiter = ",",
        [string]
        $Filter = "*.log",
        [int]
        $Age = 1
    )
    begin {
        # must be an array, so split at each ","
        $header = "ComputerName,ServiceName,Record-Date,Record-Time,Packet-Type,User-Name,Fully-Qualified-Distinguished-Name,Called-Station-ID,Calling-Station-ID,Callback-Number,Framed-IP-Address,NAS-Identifier,NAS-IP-Address,NAS-Port,Client-Vendor,Client-IP-Address,Client-Friendly-Name,Event-Timestamp,Port-Limit,NAS-Port-Type,Connect-Info,Framed-Protocol,Service-Type,Authentication-Type,Policy-Name,Reason-Code,Class,Session-Timeout,Idle-Timeout,Termination-Action,EAP-Friendly-Name,Acct-Status-Type,Acct-Delay-Time,Acct-Input-Octets,Acct-Output-Octets,Acct-Session-Id,Acct-Authentic,Acct-Session-Time,Acct-Input-Packets,Acct-Output-Packets,Acct-Terminate-Cause,Acct-Multi-Ssn-ID,Acct-Link-Count,Acct-Interim-Interval,Tunnel-Type,Tunnel-Medium-Type,Tunnel-Client-Endpt,Tunnel-Server-Endpt,Acct-Tunnel-Conn,Tunnel-Pvt-Group-ID,Tunnel-Assignment-ID,Tunnel-Preference,MS-Acct-Auth-Type,MS-Acct-EAP-Type,MS-RAS-Version,MS-RAS-Vendor,MS-CHAP-Error,MS-CHAP-Domain,MS-MPPE-Encryption-Types,MS-MPPE-Encryption-Policy,Proxy-Policy-Name,Provider-Type,Provider-Name,Remote-Server-Address,MS-RAS-Client-Name,MS-RAS-Client-Version" -split ","
    }
    process {
        $Files = Get-ChildItem -Path $Path -Filter $Filter | Where-Object LastWriteTime -gt (Get-Date).AddDays(-$age)
        foreach ($File in $Files) {
            Import-Csv -Path $file.FullName -Header $header -Delimiter $Delimiter | % {[NPSIASLog]::New($_)}
        }
    }
    end {
    }
}
