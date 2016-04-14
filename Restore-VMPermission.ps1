<#PSScriptInfo

.VERSION 1.0.1

.GUID c5fdb6c5-a3d3-4d1b-90e6-9c878dbae95b

.AUTHOR @torggler

.PROJECTURI http://www.ntsystems.it/page/PS-Restore-VMPermissionps1.aspx

.EXTERNALMODULEDEPENDENCIES Hyper-V

#>

<#
.Synopsis
    Adds permissions for the VMId to all assigned disks.
.DESCRIPTION
    This script uses the Hyper-V Module to update permissions for all assigned disks on one ore more VMs.
    This is useful if you move/replace VHDs and the read permission for VMId is missing.
.INPUTS
    You can pipe objcets with a VMName property, such as returned by Get-VM, to this script.
.OUTPUTS
    None. This script does not write any objects to the pipeline. 
.EXAMPLE
    .\Restore-VMPermission.ps1 -VM dc01

    This example adds permission for dc01 VMId to the ACL of all assigned disks for dc01.
.EXAMPLE
    Get-VM | \.Restore-VMPermission.ps1

    This example uses Get-VM to get all VMs on the local machine. It gets all disks for all VMs and adds the required premissions for VMId to the ACL.
.ROLE
    Get-VM requires administrative rights. 
.LINK
    http://www.ntsystems.it/page/PS-Restore-VMPermissionps1.aspx
#>

[CmdletBinding(ConfirmImpact='Medium',SupportsShouldProcess=$true)]
Param
(
    # VM, specify the VM that needs permissions fixed.
    [Parameter(Mandatory=$true, 
                ValueFromPipelineByPropertyName=$true, 
                Position=0,
                ParameterSetName='Parameter Set 1')]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Alias("VMName")] 
    [Alias("Name")]
    [string[]]
    $VM
)

begin {
        
    try {
        Import-Module Hyper-V -ErrorAction Stop -Verbose:$false
    } catch {
        Write-Warning -Message "$(Get-Date) Error importing Lync Module: $($_.ErrorRecord)"
        exit    
    }

} # end Begin

process {
        
    try {
        Write-Verbose 'Trying to get VM'
        $VirtualMachines = Get-Vm $VM -ErrorAction Stop -ErrorVariable GetVmError
    } 
    catch {
        Write-Warning -Message "Could get VM: $($GetVmError.ErrorRecord)"
    }

    foreach ($VirtualMachine in $VirtualMachines) {
        
        Write-Verbose "Processing VM: $($VirtualMachine.Name)"

        $colRights = [System.Security.AccessControl.FileSystemRights]"Read, Write, Synchronize" 
        $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None 
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None 
        $objType =[System.Security.AccessControl.AccessControlType]::Allow 
        $objUser = New-Object System.Security.Principal.NTAccount("NT VIRTUAL MACHINE\$($VirtualMachine.VMId)") 
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType) 

        foreach ($Disk in $VirtualMachine.HardDrives) {
            Write-Verbose "Processing VM $($VirtualMachines.Name) controller: $($Disk.ControllerNumber) disk: $($Disk.ControllerLocation)"
                $objACL = Get-ACL -Path $Disk.Path
                $objACL.AddAccessRule($objACE) 

            if ($pscmdlet.ShouldProcess("$($Disk.Path)", "Adding permission for $objUser")) {
                Set-ACL -Path $Disk.path -AclObject $objACL
            }
        } # end foreach
    } # end foreach
}  # end Process