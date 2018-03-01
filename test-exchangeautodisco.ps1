


function Test-ExchangeAutodiscover {
    [CmdletBinding()]
    param (
        [string]
        $EmailAddress,
        [string]
        $ComputerName,
        $Credential,
        [switch]
        $ExcludeExplicitO365Endpoint
    )
    
    begin {

        $domainName = $EmailAddress -split "@" | Select-Object -Last 1

        $adURIs = @{
            "root" = "https://$domainName/autodiscover/autodiscover.xml";
            "autodiscover" = "https://autodiscover.$domainName/autodiscover/autodiscover.xml";
        }

        if($ComputerName) {
            $adURIs.Add("uri","https://$ComputerName/autodiscover/autodiscover.xml")
        } elseif (-not($ExcludeExplicitO365Endpoint)) {
            $adURIs.Add("o365","https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml")
        }

      
        [xml]$body = @"
        <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
        <Request>
            <EMailAddress>$EmailAddress</EMailAddress>
            <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
        </Request>
        </Autodiscover>
"@

    }
    
    process {

        $out = @{}

        foreach($key in $adURIs.keys){
            Write-Verbose "Testing $key domain for $EmailAddress"

            try {
                $r = Invoke-RestMethod -uri $adURIs[$key] -Credential $Credential -Method post -Body $body -Headers @{"content-type"="text/xml"} -DisableKeepAlive -TimeoutSec 3 
                $out.add($key,$r.Autodiscover.Response.Account)
            } catch {
                Write-Verbose "Could not connect to $key domain"
            }
        }
        Write-Output (New-Object -TypeName psobject -Property $out)      
    }
    
    end {
    }
}


function Get-ExchangeAutodisoverRecords {
    [CmdletBinding()]
    param (
        $Domain,
        $NameServer
    )
    
    begin {
        $aRecord = "autodiscover",$domain -join "."
        $srvRecord = "_autodiscover","_tcp",$domain -join "."
    }
    
    process {
        Resolve-DnsName -Name $aRecord -Type CNAME -ErrorAction SilentlyContinue | Where-Object {$_.QueryType -notlike "SOA"}
        Resolve-DnsName -Name $srvRecord -Type SRV -ErrorAction SilentlyContinue | Where-Object {$_.QueryType -notlike "SOA"}
    }
    
    end {
    }
}

# Autodiscover behaviour
#https://support.microsoft.com/en-us/help/3211279/outlook-2016-implementation-of-autodiscover

# 1. https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml can be disabled with ExcludeExplicitO365Endpoint
# 2. SCP
# 3. Root Domain https: https://<domain>/autodiscover/autodiscover.xml 
# 4. Autodiscover Domain https: https://autodiscover.<domain>/autodiscover/autodiscover.xml 
# 5. Local Data PreferLocalXML 
# 6. HTTP Redirect from Autodiscover Domain. Ignore Acutual Autodiscover XML because retrieved incseucre. can be disabled by     ExcludeHttpRedirect
# 7. SRV Record: loops through entries and tries first https: _autodiscover._tcp.<domain name> # ExcludeSrvRecord



