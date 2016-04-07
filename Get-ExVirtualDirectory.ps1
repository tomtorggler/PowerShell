function Get-ExVirtualDirectory {
    <#
    .Synopsis
       Short description
    .DESCRIPTION
       Long description
    .EXAMPLE
       Example of how to use this cmdlet
    .EXAMPLE
       Another example of how to use this cmdlet
    .INPUTS
       Inputs to this cmdlet (if any)
    .OUTPUTS
       Output from this cmdlet (if any)
    .NOTES
       General notes
    .COMPONENT
       The component this cmdlet belongs to
    .ROLE
       The role this cmdlet belongs to
    .FUNCTIONALITY
       The functionality that best describes this cmdlet
    #>
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Param1
    )

    Begin {
        try {
            $servers = @(Get-ExchangeServer | ?{$_.ServerRole -like "*ClientAccess*" -and (($_.AdminDisplayVersion -like "*15*") -or ($_.AdminDisplayVersion -like "*14*") -and ($_.Name -like $Filter))} | Select-Object Name)
	    } catch {
            Wirte-Warning "Error getting Exchange Server"
            break
        }
    }
    
    Process {
        foreach ($server in $servers) {
           	$autodresult = Get-ClientAccessServer -Identity $server.name | Select Name,AutodiscoverServiceInternalUri 
            $autodvirdirresult = Get-AutodiscoverVirtualDirectory -Server $server.name -AdPropertiesOnly | Select InternalUrl,ExternalUrl,InternalAuthenticationMethods,ExternalAuthenticationMethods
		    $owaresult = Get-OWAVirtualDirectory -server $server.name -AdPropertiesOnly | Select Name,Server,InternalUrl,ExternalUrl,*auth*
            $ecpresult = Get-ECPVirtualDirectory -server $server.name -AdPropertiesOnly | Select Name,Server,InternalUrl,ExternalUrl
            $oaresult = Get-OutlookAnywhere -server $server.name -AdPropertiesOnly | Select Name,Server,InternalHostname,ExternalHostname,ExternalClientAuthenticationMethod,InternalClientAuthenticationMethod,IISAuthenticationMethods
            $oabresult = Get-OABVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods,OfflineAddressBooks
            $easresult = Get-ActiveSyncVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods
            $ewsresult = Get-WebServicesVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,InternalNlbBypassUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods
        }

    }

    End {
    }
}