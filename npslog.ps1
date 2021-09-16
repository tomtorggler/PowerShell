[CmdletBinding()]
param($filename)

$PACKET_TYPES = @{ 
    1 = "Access-Request"; 
    2 = "Access-Accept"; 
    3 = "Access-Reject"; 
    4 = "Accounting-Request";
   5 = "Accounting-Response";
   6 = "Accounting-Status";
   7 = "Password-Request";
   8 = "Password-Ack";
   9 = "Password-Reject";
   10 = "Accounting-Message";
   11 = "Access-Challenge";
   21 = "Resource-Free-Request";
   22 = "Resource-Free-Response";
   23 = "Resource-Query-Request";
   24 = "Resource-Query-Response";
   25 = "Alternate-Resource-Reclaim-Request";
   26 = "NAS-Reboot-Request";
   27 = "NAS-Reboot-Response";	
   29 = "Next-Passcode";
   30 = "New-Pin";
   31 = "Terminate-Session";
   32 = "Password-Expired";
   33 = "Event-Request";
   34 = "Event-Response"; 	
   40 = "Disconnect-Request";
   41 = "Disconnect-ACK";
   42 = "Disconnect-NAK";
   43 = "CoA-Request";
   44 = "CoA-ACK";
   45 = "CoA-NAK";
   50 = "IP-Address-Allocate";
   51 = "IP-Address-Release";
} 

$SERVICE_TYPES = @{
 1 =	"Login";
 2 =	"Framed";
 3 =	"Callback Login";
 4 =	"Callback Framed";
 5 =	"Outbound";
 6 =	"Administrative";
 7 =	"NAS Prompt";
 8 =	"Authenticate Only";
 9 =	"Callback NAS Prompt";
 10 = "Call Check";
 11 = "Callback Administrative";
 12 = "Voice";
 13 = "Fax";
 14 = "Modem Relay";
 15 = "IAPP-Register";
 16 = "IAPP-AP-Check";
 17 = "Authorize Only";
 18 = "Framed-Management"
 19 = "Additional-Authorization"
}

$AUTHENTICATION_TYPES = @{ 
   1 = "PAP";
  2 = "CHAP";
  3 = "MS-CHAP";
  4 = "MS-CHAP v2";
  5 = "EAP";
  7 = "None";
  8 = "Custom";
  11 = "PEAP"
}  

$REASON_CODES = @{ 
  0 = "IAS_SUCCESS"; 
  1 = "IAS_INTERNAL_ERROR"; 
  2 = "IAS_ACCESS_DENIED"; 
  3 = "IAS_MALFORMED_REQUEST"; 
 4 = "IAS_GLOBAL_CATALOG_UNAVAILABLE"; 
  5 = "IAS_DOMAIN_UNAVAILABLE"; 
  6 = "IAS_SERVER_UNAVAILABLE"; 
 7 = "IAS_NO_SUCH_DOMAIN"; 
  8 = "IAS_NO_SUCH_USER"; 
  16 = "IAS_AUTH_FAILURE"; 
  17 = "IAS_CHANGE_PASSWORD_FAILURE"; 
 18 = "IAS_UNSUPPORTED_AUTH_TYPE"; 
  32 = "IAS_LOCAL_USERS_ONLY"; 
  33 = "IAS_PASSWORD_MUST_CHANGE"; 
  34 = "IAS_ACCOUNT_DISABLED"; 
  35 = "IAS_ACCOUNT_EXPIRED"; 
  36 = "IAS_ACCOUNT_LOCKED_OUT"; 
  37 = "IAS_INVALID_LOGON_HOURS"; 
  38 = "IAS_ACCOUNT_RESTRICTION"; 
  48 = "IAS_NO_POLICY_MATCH"; 
  64 = "IAS_DIALIN_LOCKED_OUT"; 
  65 = "IAS_DIALIN_DISABLED"; 
  66 = "IAS_INVALID_AUTH_TYPE"; 
  67 = "IAS_INVALID_CALLING_STATION"; 
  68 = "IAS_INVALID_DIALIN_HOURS"; 
  69 = "IAS_INVALID_CALLED_STATION"; 
  70 = "IAS_INVALID_PORT_TYPE"; 
  71 = "IAS_INVALID_RESTRICTION"; 
  80 = "IAS_NO_RECORD"; 
  96 = "IAS_SESSION_TIMEOUT"; 
  97 = "IAS_UNEXPECTED_REQUEST"; 
} 

$ACCT_TERMINATE_CAUSES = @{
 1 =	"User Request";
 2 =	"Lost Carrier";
 3 =	"Lost Service";
 4 =	"Idle Timeout";
 5 =	"Session Timeout";
 6 =	"Admin Reset";
 7 =	"Admin Reboot";
 8 =	"Port Error";
 9 =	"NAS Error";
 10 = "NAS Request";
 11 = "NAS Reboot";
 12 = "Port Unneeded";
 13 = "Port Preempted";
 14 = "Port Suspended";
 15 = "Service Unavailable";
 16 = "Callback";
 17 = "User Error";
 18 = "Host Request";
 19 = "Supplicant Restart";
 20 = "Reauthentication Failure";
 21 = "Port Reinitialized";
 22 = "Port Administratively Disabled";
 23 = "Lost Power";
}

$ACCT_STATUS_TYPES = @{
 1 =	"Start";
 2 =	"Stop";
 3 =	"Interim-Update";	
 7 =	"Accounting-On";
 8 =	"Accounting-Off";
 9 =	"Tunnel-Start";
 10 = "Tunnel-Stop";
 11 = "Tunnel-Reject";
 12 = "Tunnel-Link-Start";
 13 = "Tunnel-Link-Stop";
 14 = "Tunnel-Link-Reject";
 15 = "Failed";
}

$ACCT_AUTHENTICS = @{
 1 =	"RADIUS";
 2 =	"Local";
 3 =	"Remote";
 4 =	"Diameter";
}


$header = "ComputerName","ServiceName","Record-Date","Record-Time","Packet-Type","User-Name","Fully-Qualified-Distinguished-Name","Called-Station-ID","Calling-Station-ID","Callback-Number","Framed-IP-Address","NAS-Identifier","NAS-IP-Address","NAS-Port","Client-Vendor","Client-IP-Address","Client-Friendly-Name","Event-Timestamp","Port-Limit","NAS-Port-Type","Connect-Info","Framed-Protocol","Service-Type","Authentication-Type","Policy-Name","Reason-Code","Class","Session-Timeout","Idle-Timeout","Termination-Action","EAP-Friendly-Name","Acct-Status-Type","Acct-Delay-Time","Acct-Input-Octets","Acct-Output-Octets","Acct-Session-Id","Acct-Authentic","Acct-Session-Time","Acct-Input-Packets","Acct-Output-Packets","Acct-Terminate-Cause","Acct-Multi-Ssn-ID","Acct-Link-Count","Acct-Interim-Interval","Tunnel-Type","Tunnel-Medium-Type","Tunnel-Client-Endpt","Tunnel-Server-Endpt","Acct-Tunnel-Conn","Tunnel-Pvt-Group-ID","Tunnel-Assignment-ID","Tunnel-Preference","MS-Acct-Auth-Type","MS-Acct-EAP-Type","MS-RAS-Version","MS-RAS-Vendor","MS-CHAP-Error","MS-CHAP-Domain","MS-MPPE-Encryption-Types","MS-MPPE-Encryption-Policy","Proxy-Policy-Name","Provider-Type","Provider-Name","Remote-Server-Address","MS-RAS-Client-Name","MS-RAS-Client-Version"
$data = Import-Csv $filename -Header $header 

foreach ($obj in $data) {

    if ($obj.'Packet-Type') {
        $obj.'Packet-Type' = $PACKET_TYPES[[int]$obj.'Packet-Type']
    }
    if ($obj.'Authentication-Type') {
        $obj.'Authentication-Type' = $AUTHENTICATION_TYPES[[int]$obj.'Authentication-Type']
    }
    if ($obj.'Reason-Code') {
        $obj.'Reason-Code' = $REASON_CODES[[int]$obj.'Reason-Code']
    }
    if ($obj.'Acct-Terminate-Cause') {
        $obj.'Acct-Terminate-Cause' = $ACCT_TERMINATE_CAUSES[[int]$obj.'Acct-Terminate-Cause']
    }
    if ($obj.'Service-Type') {
        $obj.'Service-Type' = $SERVICE_TYPES[[int]$obj.'Service-Type']
    }
    if ($obj.'Acct-Status-Type') {
        $obj.'Acct-Status-Type' = $ACCT_STATUS_TYPES[[int]$obj.'Acct-Status-Type']
    }
    if ($obj.'Acct-Authentic') {
        $obj.'Acct-Authentic' = $ACCT_AUTHENTICS[[int]$obj.'Acct-Authentic']
    }
}

$data