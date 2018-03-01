function Get-VirtualDir {
    param(
        $ExchangeServer,
        [switch]$AdProp
    )

    foreach($server in $ExchangeServer) {

        $param = @{
            'Server' = $server;
            'ADPropertiesOnly' = $true;
            'ErrorAction' = 'Stop';
        }

        try {
            $owa = Get-OwaVirtualDirectory @param
            $ews = Get-WebServicesVirtualDirectory @param
            $oab = Get-OabVirtualDirectory @param
            $mapi = Get-MapiVirtualDirectory @param
            $autodiscover = Get-ClientAccessService -Identity $server
            $oa =  Get-OutlookAnywhere @param
            $eas = Get-ActiveSyncVirtualDirectory @param 
        
            $out = @{
                'internal' = @{
                    'Server' = $server
                    'OWA' = $owa.InternalUrl
                    'EWS' = $ews.InternalUrl
                    'OAB' = $oab.InternalUrl
                    'EAS' = $eas.InternalUrl
                    'Mapi' = $mapi.InternalUrl
                    'OutlookAnywhere' = $oa.InternalHostname 
                    'Autodiscover' = $autodiscover.AutoDiscoverServiceInternalUri
                };
                'external'  = @{
                    'Server' = $server
                    'OWA' = $owa.ExternalUrl
                    'Ews' = $ews.ExternalUrl
                    'OAB' = $oab.ExternalUrl
                    'EAS' = $eas.ExternalUrl
                    'Mapi' = $mapi.ExternalUrl
                    'OutlookAnywhere' = $oa.ExternalHostname
                }
            }
            
            $out
        } catch {
            Write-Warning "Could not connect to $_"
        }
    
    }

}




