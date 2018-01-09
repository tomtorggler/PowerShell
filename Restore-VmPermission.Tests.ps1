
# Define variables for Mock runs
$global:mockedVM = [pscustomobject] @{
    Name = "My VM 01"
    VmId = (New-Guid).ToString()
    HardDrives = @{
        ControllerNumber = 0
        ControllerLocation = 0
        Path = "myvhd.vhd" 
    }
}

# Testing with mocked commands
Describe "Testing Restore-VmPermission" {
    
    Mock Get-VM -MockWith {return $global:mockedVM} -verifiable
    
    $VhdPath = Join-Path -Path $TestDrive -ChildPath "myvhd.vhd"

    Context "Testing Prerequisites" {
        It "Test Hyper-V PowerShell module" {
            $module = Get-Module -Name Hyper-V -ListAvailable -ErrorAction SilentlyContinue
            $module -is [PSModuleInfo] | Should be $true
        }
        It "Test Get-VM Connectivity" {
            $vm = Get-VM
            $vm | Should Not Be $null
        }
    }
}