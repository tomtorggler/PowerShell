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
        $Param1,

        [string]
        $filter = "*"
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
        $result = @()
        $i=0
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting Autodiscover URL information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $casServ = Get-ClientAccessServer -Identity $server.name | Select Name,AutodiscoverServiceInternalUri
            $result += $casServ
            Clear-Variable -Name casServ
        }
        $i=0
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting Autodiscover VD information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $autoDisco = Get-AutodiscoverVirtualDirectory -Server $server.name -AdPropertiesOnly | Select Name,Server,InternalAuthenticationMethods,ExternalAuthenticationMethods
            $result += $autoDisco
            Clear-Variable -Name autoDisco
        }
        $i=0
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting OWA VD information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $owa = Get-OWAVirtualDirectory -server $server.name -AdPropertiesOnly | Select Name,Server,InternalUrl,ExternalUrl,InternalAuthenticationMethods,ExternalAuthenticationMethods
            $result += $owa
            Clear-Variable -Name owa
        }
        $i=0
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting ECP VD information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $ecp = Get-ECPVirtualDirectory -server $server.name -AdPropertiesOnly | Select Name,Server,InternalUrl,ExternalUrl,InternalAuthenticationMethods,ExternalAuthenticationMethods
            $result += $ecp
            Clear-Variable -Name ecp
        }
        $i=0
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting Outlook Anywhere information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $oa = Get-OutlookAnywhere -server $server.name -AdPropertiesOnly | Select Name,Server,InternalHostname,ExternalHostname,ExternalClientAuthenticationMethod,InternalClientAuthenticationMethod,IISAuthenticationMethods
            $result += $oa
            Clear-Variable -Name oa
        }
        $i=0        
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting OAB VD information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $oab = Get-OABVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods,OfflineAddressBooks
            $result += $oab
            Clear-Variable -Name oab
        }    
        $i=0    
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting ActiveSync VD information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $eas = Get-ActiveSyncVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods
            $result += $eas
            Clear-Variable -Name eas
        }   
        $i=0     
        foreach ($server in $servers) {
            $i++
            Write-Progress -Activity "Getting Web Services information" -Status "Progress:"-PercentComplete (($i / $servers.count)*100)
            $ws = Get-WebServicesVirtualDirectory -server $server.name -AdPropertiesOnly | Select Server,InternalUrl,InternalNlbBypassUrl,ExternalUrl,ExternalAuthenticationMethods,InternalAuthenticationMethods
            $result += $ws
            Clear-Variable -Name ws
        }
        
        $result            

    }

    End {
    }
}