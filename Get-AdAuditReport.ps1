function Get-ADAuditReport {
    <#
    .Synopsis
       Get 20 random users from Active Directory.
    .DESCRIPTION
       This function gets a number of random users from Active Directory and displays the following information about them: SamAccountName, Department, Title, LastLogonTimeStamp, PasswordLastSet, Enabled, LockedOut.
       The number of users to query can be specified using the -ResultSetSize parameter, the number of random users to select out of the result set can be specified using the -Count parameter.
       The function creates an HTML report at a location spcified by -Path. The report will be opened using the default browser.
       If the ActiveDirectory PowerShell Module cannot be loaded locally, the function tries to create a PSRemoting session with a DC found by FindDomainController(). The -DomainController and -Credential parameters
       can be used to connect to a spcifiy Domain Contoller using specified credentials.
       If the ActiveDirectory PowerShell Module is available locally, it will always be preferd and -DomainController is ignored.
    .EXAMPLE
       Get-AdAuditReport -Path C:\temp\report.htm

       This example gets 512 users from Active Directory, it then randomly selects 20 of them and creates an audit report at c:\temp\report.htm. The report will be opened using the default browser.
    .EXAMPLE
       Get-AdAuditReport -Path C:\temp\report.htm -Count 40 -PassThru

       This example gets 512 users from Active Directory, it then randomly selects 40 of them and creates an audit report at c:\temp\report.htm. The report will be opened using the default browser. 
       It also writes psobjects to the pipeline.
    .EXAMPLE
       Get-AdAuditReport -Path C:\temp\report.htm -DomainController dc01 -Credential (Get-Credential) -ResultSetSize 1000 -Count 10

       If the ActiveDirectory Module cannot be imported, this example tries to establish a PsRemoting session with dc01 using the credentials submitted by Get-Credential.
       It will then get 1000 users from AD and randomly select 10 of them. The report will again be generated at C:\temp\report.htm and be opened using the default browser.
    .OUTPUTS
       [psobject]
    .NOTES
       This function was created for the Scripting Games 2013.
       Author: thomas torggler; @torggler
       Date: 2013-05-20
    #>
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Specify a path for the HTML report, filename must end in html or htm.
        [Parameter(Mandatory=$true, 
                   Position=0)]
        [ValidatePattern("\.html$|\.htm$")]
        [Alias("Report")] 
        [System.IO.FileInfo]
        $Path,

        # Specify the number of random accounts to get from AD. Defaults to 20.
        [Parameter(Position=1)]
        [ValidateRange(1,1000)]
        [int]
        $Count = 20,

        # Specify Domain Controller to connect to, uses FindDomainController() as a default value.
        [Parameter(Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullorEmpty()]
        [Alias("DC")]
        [string]
        $DomainController = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().FindDomainController().Name,

        # Specify credentials to connect to the Domain Controller. 
        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Specify ResultSetSize for Get-ADUser command. Defaults to 512.
        [Parameter(Position=3)]
        [ValidateRange(1,4000)]
        [Alias("Set")]
        [int]
        $ResultSetSize = 512,
        
        # Speficy ResultPageSize for Get-ADUser command. Defaults to 256.
        [Parameter(Position=4)]
        [ValidateRange(1,2000)]
        [Alias("Page")]
        [int]
        $ResultPageSize = 256,

        # Output objects to the pipeline
        [switch]
        $PassThru
    )

    ### no use for begin, process, end blocks as there is nothing piped in here.
        
    ### try to create an empty new repot file to check permissions 
    try {
        New-Item -Path $Path -ItemType File -Force -ErrorAction Stop -ErrorVariable CreatePathError | Out-Null
    } catch {
        Write-Warning -Message "Could not create file: $($CreatePathError.ErrorRecord) Report will not be available"
    }    

    ### try importing ActiveDirectory Module
    if ((Get-Module -ListAvailable ActiveDirectory) -ne $null) {
        Write-Verbose "ActiveDirectory Module found, trying to import"
        try {
            Import-Module ActiveDirectory -ErrorAction Stop -ErrorVariable ImportModuleError
        } catch {
            Write-Warning "Could not import ActiveDirectory PowerShell Module $($ImportModuleError.ErrorRecord)"
        }
    } else {
        Write-Verbose "Active Directory Module not found, trying to connect to $DomainController"
        try {
	        $ADSession = New-PSSession -Name AD -ComputerName $DomainController -Credential $Credential -ErrorAction Stop -ErrorVariable PSSessionError
	        Invoke-Command -Session $ADSession -ScriptBlock {Import-Module ActiveDirectory}
            Import-PSSession $ADSession -CommandName Get-ADUser | Out-Null
        } catch {
            Write-Warning "Could not connect to $DomainController $($PSSessionError.ErrorRecord)"
        }
    }

    if (Get-Command Get-ADUser -ErrorAction SilentlyContinue) {
        Write-Verbose "Get-ADUser command found, getting $ResultSetSize users"
        
        ### Getting AD Users with needed properties, using LastLogonTimeStamp because it is replicated between DomainControllers. 
        ### LastLogon would provide more up to date information, but is only updated on the validating DC.
        
        $getAdUser = @{
            'Filter'='*';
            'ResultSetSize'=$ResultSetSize;
            'ResultPageSize'=$ResultPageSize
        }
        ### Getting users from AD                         
        $RandomUsers = Get-ADUser @getAdUser -Properties Department, Title, LockedOut, LastLogonTimeStamp, PasswordLastSet | Get-Random -Count $Count
        $AuditReport = @()

        foreach ($User in $RandomUsers) {
        $AuditInfo = [ordered]@{
                'Username' = $User.SamAccountName;
                'Department' = $User.Department;
                'Title' = $User.Title;
                'LastLogonTime' = [datetime]::FromFileTime($User.LastLogonTimeStamp);
                'PasswordLastSet' = $User.PasswordLastSet;
                'AccountDisabled' = -not $User.Enabled;
                'AccountLockedOut' = $User.LockedOut
            }
            if ($User.LastLogonTimeStamp -eq $null) {
                $AuditInfo.LastLogonTime = "never"
            }
            if ($User.PasswordLastSet -eq $null) {
               $AuditInfo.PasswordLastSet = "never"
            }
            
            ### Add all user information objects to a single object
            $AuditReport += New-Object -TypeName PsObject -Property $AuditInfo

        } # end foreach $user
        
        ### if PassThru parameter is set, write objects to the pipeline
        if ($PassThru){
            Write-Output $AuditReport 
        }

        ### parameters for ConvertTo-Html
        $htmlParam = @{
            'Title'='Active Directory Audit Report'
            'PreContent'="<H2>Audit Report for $($Count) users out of $($ResultSetSize)</H2>";
            'PostContent'="<HR> $(Get-Date)"
        }

        ### convert the collection to HTML and write it to a file
        $AuditReport | ConvertTo-Html @htmlParam | Add-Content -Path $Path

        ### open the HTML report in the default browser
        Start-Process $Path
    } # end if 
    
} # end function Get-AdAuditReport