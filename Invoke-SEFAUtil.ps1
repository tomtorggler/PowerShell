
<#PSScriptInfo

.VERSION 1.2

.GUID 4b189c97-f8b3-4d7a-a40b-fae21710b4ef

.AUTHOR @torggler

.TAGS Lync,Skype

.PROJECTURI https://ntsystems.it/post/invoke-sefautil-a-powershell-wrapper-function

.EXTERNALMODULEDEPENDENCIES Lync

#>

<#
.Synopsis
   Invoke SEFAUtil with some parameters and validation.
.DESCRIPTION
   This is a wrapper function for the SEFAUtil tool from the Lync Resource Kit Tools. It's intendet purpose is to make dealing with the cmdline tool easier.
   The default Value for the Path parameter assumes Skype for Business 2015 Resource Kit Tools are installed at C:\Program Files\Skype for Business Server 2015\ResKit.
   This function requires version 3 of PowerShell as well as the Lync or SkypeForBusiness Module for user validation with Get-CsUser.
.NOTES
   Author: @torggler
   Date: 2018-03-01
   Disclaimer: Do not run this script in a production environment! The script is provided AS IS without warranty of any kind!
.INPUTS
   [Microsoft.Rtc.Management.ADConnect.Schema.OCSADUserBase[]]
   You can pipe objects of the type OCSADUserBase, such as retrieved by Get-CsUser, to this script.
.OUTPUTS
   [psobject]
   This script writes custom objects to the pipeline.
.EXAMPLE
   .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Username thomas@tomt.it

   This example invokes SEFAUtil without additional parameters, call forwarding settings for the user thomas@tomt.it are shown.
.EXAMPLE
   .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Username thomas@tomt.it -EnableSimulRing +391231234567

   This example enables Simul Ring for the user thomas@tomt.it. The destination number for Simul Ring is +391231234567.
.EXAMPLE
   .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Username thomas@tomt.it -AddTeamMember user10@tomt.it

   This example adds user10@tomt.it to thomas@tomt.it. This will also enable Simul Ring for the user.
.EXAMPLE
   .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Username thomas@tomt.it -DelayRingTeam 10

   This example set's the delay for Team Calls to 10 seconds for the user thomas@tomt.it
.EXAMPLE
   .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Username thomas@tomt.it -DisableTeamCall

   This example disables Team Call for thomas@tomt.it
.EXAMPLE
   Get-CsUser -OU "OU=users,OU=tomt,DC=tomt,DC=local" | .\Invoke-SEFAUtil.ps1 -Server ly15.tomt.local -Verbose -AddDelegate user1@tomt.it

   This example uses Get-CsUser to get all Lync Users from within the specified Organizational Unit and adds user1@tomt.it as delegate.
.LINK
   https://ntsystems.it/PowerShell/Invoke-SEFAUtil/
   https://ntsystems.it/post/invoke-sefautil-a-powershell-wrapper-function
   http://technet.microsoft.com/en-us/library/jj945604.aspx
#>

#Requires -Version 3 
#Requires -Module Lync
#Requires -RunAsAdministrator

[CmdletBinding(DefaultParameterSetName='TeamCall',
                SupportsShouldProcess=$true, 
                ConfirmImpact='Medium')]
[OutputType([psobject])]
Param
(
    # Path specifies the Path to the sefautil.exe file
    [Parameter(Mandatory=$false,Position=0)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]
    $Path="C:\Program Files\Skype for Business Server 2015\ResKit\SefaUtil.exe",
     
    # Server, specify the Lync Server FQDN
    [Parameter(Mandatory=$true,Position=1)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [validatepattern('\w+\.\w*')]
    [String]
    $Server,

    # InputObject, used for pipeline input processing
    [Parameter(ValueFromPipeline=$true)]
    [Microsoft.Rtc.Management.ADConnect.Schema.OCSADUserBase[]]
    $InputObject,
     
    # UserName use the UserPrincipalName to specify one or more users to modify
    [Parameter(Mandatory=$false,
        Position=2)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Get-CsUser -Identity "sip:$_"})]
    [Alias('UserPrincipalName')]
    [string[]]
    $Username,

    # Logfile, specify a path to the LogFile
    [Parameter(Mandatory=$false,Position=4)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]
    $LogFile="$env:TEMP\log-Invoke-SEFAUtil.txt",
                
    # AddDelegate uses the /adddelegate parameter to add a delegate on-behalf of the user
    [Parameter(Mandatory=$false, 
                ParameterSetName='Delegates')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Get-CsUser -Identity "sip:$_"})]
    [String]
    $AddDelegate,
        
    # RemoveDelegates uses the /removedelegate parameter to remove delegate on behalf of the user
    [Parameter(Mandatory=$false, 
                ParameterSetName='Delegates')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Get-CsUser -Identity "sip:$_"})]
    [String]
    $RemoveDelegate,

    # delayringdelegates uses to /delayringdelegates parameter to set number of seconds Boss' endpoints rings before ringing delegates
    [Parameter(Mandatory=$false, 
                ParameterSetName='Delegates')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(0,5,10,15)]
    [int]
    $DelayRingDelegates,
        
    # FwdToDelegates Sets user's call handling rules to forward calls to delegates
    [Parameter(Mandatory=$false,
                ParameterSetName='Delegates')]
    [switch]
    $FwdToDelegates,
                
    #SimulRingDelegates, Sets user's call handling rules to ring delegates endpoints simultaneously
    [Parameter(Mandatory=$false,
                ParameterSetName='Delegates')]
    [switch]
    $SimulRingDelegates,
                
    # DisableDelegation disables delegate ringing for the user
    [Parameter(Mandatory=$false,
                ParameterSetName='Delegates')]
    [switch]
    $DisableDelegation,

    # enablesimulring uses the /setsimulringdestination and /enablesimulring parameters to enable simultaneous ringing and specify the the destination number
    [Parameter(Mandatory=$false, 
                ParameterSetName='SimulRing')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [string]
    $EnableSimulRing,

    #disablesimulring disables Simul Ring
    [Parameter(Mandatory=$false,
                ParameterSetName='SimulRing')]
    [switch]
    $DisableSimulRing,

    # addteammember add team member on-behalf of the user
    [Parameter(Mandatory=$false, 
                ParameterSetName='TeamCall')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Get-CsUser -Identity "sip:$_"})]
    [string]
    $AddTeamMember,
        
    # removeteammember removes team member on behalf of the user
    [Parameter(Mandatory=$false, 
                ParameterSetName='TeamCall')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Get-CsUser -Identity "sip:$_"})]
    [string]
    $RemoveTeamMember,

    # delayringteam sets number of seconds user's endpoints ring before ringing team members
    [Parameter(Mandatory=$false, 
                ParameterSetName='TeamCall')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(0,5,10,15)]
    [int]
    $DelayRingTeam,

    # disableteamcall disables team ringing for the user
    [Parameter(Mandatory=$false,
                ParameterSetName='TeamCall')]
    [switch]
    $DisableTeamCall,

    # simulringteam sets user's call handling rules to ring team member endpoints simultaneously
    [Parameter(Mandatory=$false,
                ParameterSetName='TeamCall')]
    [switch]
    $SimulRingTeam,

    #enablefwdnoanswer
    [Parameter(Mandatory=$false, 
               ParameterSetName='Forward')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [string]
    $EnableFwdNoAnswer,
    
    #enablefwdimmediate
    [Parameter(Mandatory=$false, 
               ParameterSetName='Forward')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [string]
    $EnableFwdImmediate,

    #callanswerwaittime
    [Parameter(Mandatory=$false, 
               ParameterSetName='Forward')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(5,10,15,20,25,30,35,40,45,50,55,60)]
    [int]
    $CallAnswerwaitTime,
    
    # disablefwdimmediate
    [Parameter(Mandatory=$false,
                ParameterSetName='Forward')]
    [switch]
    $DisableFwdImmediate,
    
    # disablefwdnoanswer
    [Parameter(Mandatory=$false,
                ParameterSetName='Forward')]
    [switch]
    $DisableFwdNoAnswer    
)
    
Begin
{
    # save the current location, then change location to the ResKit directory
    $CurrentLocation = Get-Location
    Set-Location $Path.DirectoryName
    Write-Verbose "Changed Location to $($Path.DirectoryName)"

    # delete existing logfile, and create a new one
    Remove-Item -Path $logfile -ErrorAction SilentlyContinue -WhatIf:$false
    "$(Get-Date) Invoke-SEFAUtil started" | Add-Content $LogFile -WhatIf:$false

    # Write location of logfile to host
    Write-Host "LogFile: $LogFile" -ForegroundColor Yellow
}

Process
{
    if ($InputObject){
        Write-Verbose "Pipeline input used"
        $Username = ($InputObject.SipAddress -replace("sip:"))
    }
    
    foreach ($user in $Username) {
        Write-Verbose "User is $user"

        $SEFAUtil = ".\SEFAUtil.exe"
        $SEFAParameters = ""

        # Evaluate PSBoundParameters and set parameters for SEFAUtil accordingly
        switch($PsCmdlet.ParameterSetName) {
            "Delegates" {
                Write-Verbose "ParameterSetName: $($PsCmdlet.ParameterSetName)"
                switch($PSBoundParameters.Keys) {
                    'AddDelegate' {$SEFAParameters += " /adddelegate:sip:$addDelegate"}
                    'FwdToDelegates' {$SEFAParameters += " /fwdtodelegates"}
                    'SimulRingDelegates' {$SEFAParameters += " /simulringdelegates"}
                    'DelayRingDelegates' {$SEFAParameters += " /delayringdelegates:$DelayRingDelegates"}
                    'RemoveDelegate' {$SEFAParameters += " /removedelegate:sip:$RemoveDelegate" }
                    'DisableDelegation' {$SEFAParameters += " /disabledelegation"}
                }                  
            }
            "SimulRing" {
                Write-Verbose "ParameterSetName: $($PsCmdlet.ParameterSetName)"
                switch($PSBoundParameters.Keys) {
                    'EnableSimulRing'{$SEFAParameters += " /setsimulringdestination:$EnableSimulRing /enablesimulring"}
                    'DisableSimulRing' {$SEFAParameters += " /disablesimulring"}
                }
            }
            "TeamCall" {
                Write-Verbose "ParameterSetName: $($PsCmdlet.ParameterSetName)"
                switch($PSBoundParameters.Keys) {
                    'AddTeamMember'{$SEFAParameters += " /addteammember:sip:$AddTeamMember"}
                    'SimulRingTeam' {$SEFAParameters += " /simulringteam"}
                    'DelayRingTeam' {$SEFAParameters += " /delayringteam:$DelayRingTeam"}
                    'RemoveTeamMember' {$SEFAParameters += " /removeteammember:sip:$RemoveTeamMember"}
                    'DisableTeamCall'{$SEFAParameters += " /disableteamcall"}
                }
            }
            "Forward" {
                Write-Verbose "ParameterSetName: $($PsCmdlet.ParameterSetName)"
                switch($PSBoundParameters.Keys) {
                    'EnableFwdNoAnswer'{$SEFAParameters += " /enablefwdnoanswer /setfwddestination:$EnableFwdNoAnswer"}
                    'EnableFwdImmediate'{$SEFAParameters += " /enablefwdimmediate /setfwddestination:$EnableFwdImmediate"}
                    'CallAnswerWaitTime' {$SEFAParameters += " /callanswerwaittime:$CallAnswerwaitTime"}
                    'DisableFwdImmediate' {$SEFAParameters += " /disablefwdimmediate"}
                    'DisableFwdNoAnswer'{$SEFAParameters += " /disablefwdnoanswer"}
                }
            }       
        } # end Switch
                
        if ($pscmdlet.ShouldProcess("sip:$user","$($SEFAUtil + $SEFAParameters)")) {

            # Invoking SEFAUtil.exe with Parameters defined above, capturing output into a String Variable to make writing logfiles easier
            $SEFAResult = Invoke-Expression -Command ($SEFAUtil + $SEFAParameters + " /server:$server sip:$user") 
            
            # Split the content of $SEFAResult
            $SEFAResultSplit = $SEFAResult -split ': '
            $OutData = $null
            
            # looping through the array, create key:value pairs and add them to $outData
                for ($i = 0; $i -lt $SEFAResultSplit.Count; $i++) {
                    if ([bool]!($i%2)) {
                        $j = $i + 1 
                        $outData += @{$SEFAResultSplit[$i] = $SEFAResultSplit[$j]}
                    }
                }

            # create custom object and write it to the pipeline
            Write-Output (New-Object -TypeName psobject -Property $OutData)
                
            # Writing output to the logfile
            "$(Get-Date) $SEFAResult" | Add-Content -Path $LogFile
        }
    } # end foreach user
} #end process

End
{
    # set location back to where we have been originally
    Set-Location $CurrentLocation
    Write-Verbose "Changed Location back to original"

    "$(Get-Date) Invoke-SEFAUtil finished running, we manipulated $($Username.count) user(s)" | Add-Content $LogFile -WhatIf:$false
}