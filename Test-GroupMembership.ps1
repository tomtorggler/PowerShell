<#PSScriptInfo

.VERSION 1.0.1

.GUID 87079941-27c8-44b1-af29-2fb447ccb883

.AUTHOR @torggler

.PROJECTURI https://ntsystems.it/PowerShell/Test-GroupMembership

.TAGS ActiveDirectory

.EXTERNALMODULEDEPENDENCIES ActiveDirectory

#>

<#
.Synopsis
    Test AD Group Membership for an account.
.DESCRIPTION
    This function uses [ADSI] to test group membership based on the security token of the account.
    You can pipe objects of the type [Microsoft.ActiveDirectory.Management.ADAccount[]] to this function.
    The function writes $true or $false fore each tested object.
    This function makes use of Richard Muellers "PowerShell script to check group membership". Check the related Links.
.EXAMPLE
    Get-AdUser -Filter * | .\Test-GroupMemership.ps1 -GroupName "Domain Users"
    
    This example gets users from Active Directory and tests wether or not they are member of the "Domain Users" security group.
.EXAMPLE
    Get-AdComputer -Filter * | .\Test-GroupMemership.ps1 -GroupName "Domain Computers"
    
    This example gets computers from Active Directory and tests wether or not they are member of the "Domain Computers" security group.
.INPUTS
    [Microsoft.ActiveDirectory.Management.ADAccount]
    You can pipe an ADAccount object, such as returned by Get-AdUser or Get-AdComputer, to Test-GroupMembership.
.OUTPUTS
    [bool]
    Test-GroupMembership returns $true or $false for each tested account.
.LINK 
    http://www.ntsystems.it/page/PS-Test-GroupMembership.aspx
.LINK
    http://gallery.technet.microsoft.com/scriptcenter/5adf9ad0-1abf-4557-85cd-657da1cc7df4
#> 

[CmdletBinding(PositionalBinding=$true)]
[OutputType([bool])]

Param(
    # InputObject, an Object of the Type [Microsoft.ActiveDirectory.Management.ADAccount]
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                Position=1)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Microsoft.ActiveDirectory.Management.ADAccount[]]
    $InputObject,

    # GroupName, the name of the Group to test
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true, 
                Position=0)]
    [ValidateScript({Get-ADGroup -Identity $_ -ErrorAction Stop})] 
    $GroupName
)

process {
    foreach ($Object in $InputObject) {
        $GroupList = @{}  

        # get ADSI object for user
        Write-Verbose "Creating ADSI Object for $($Object.SamAccountName)"
        $AdObject = [ADSI]"LDAP://$($Object.DistinguishedName)" 
            
        # Check if security group memberships for this principal have been determined. 
        If ($GroupList.ContainsKey($ADObject.sAMAccountName.ToString() + "\") -eq $False) 
        { 
            # Memberships need to be determined for this principal. Add "pre-Windows 2000" 
            # name to the hash table. 
            $GroupList.Add($ADObject.sAMAccountName.ToString() + "\", $True) 
    
            # Retrieve tokenGroups attribute of principal, which is operational. 
            $ADObject.psbase.RefreshCache("tokenGroups") 
            $SIDs = $ADObject.psbase.Properties.Item("tokenGroups") 
    
            # Populate hash table with security group memberships. 
            ForEach ($Value In $SIDs) 
            { 
                $SID = New-Object System.Security.Principal.SecurityIdentifier $Value, 0
                
                if ($sid.BinaryLength -gt 16) {
                    # the length is used to skip well-known SIDs that cannot be translated to NTAccount
                    # Translate into "pre-Windows 2000" name.
                
                    $Group = $SID.Translate([System.Security.Principal.NTAccount])
                    $GroupList.Add($ADObject.sAMAccountName.ToString() + "\" + $Group.Value.Split("\")[1], $True)
                } 
            } 
        } 

        # Check if $ADObject is a member of $GroupName. 
        If ($GroupList.ContainsKey($ADObject.sAMAccountName.ToString() + "\" + $GroupName)) { 
            Write-Verbose "$($Object.SamAccountName) is member of $GroupName"
            Return $True 
        } else { 
            Write-Verbose "$($Object.SamAccountName) is not member of $GroupName"
            Return $False 
        }
    } 
}