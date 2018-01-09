# find current path to use when starting process
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Describe "Testing Web Server" {    
    # Start another instance of powershell as the script blocks the console
    # use Verb RunAs to start the new instance as admin
    Start-Process powershell -Argument "$here\Start-TestWebServer.ps1 -Port 80 -CreateFirewallRule" -Verb RunAs
    # Wait a sec for the instance to come up
    Start-Sleep -Seconds 5
    Context "Starting" {
        It "Creates a firewall rule upon starting" {
            (Get-NetFirewallRule -PolicyStore ActiveStore -DisplayName "Allow PS TestWS Port*") -is [Microsoft.Management.Infrastructure.CimInstance]  | Should Be True  
        }
        It "creates a listening tcp connection" {
            (Get-NetTCPConnection -LocalPort 80 -State Listen) -is [Microsoft.Management.Infrastructure.CimInstance]  | Should Be True
        }
        It "returns the requests as json object" {
            $response = Invoke-RestMethod http://localhost/
            $response | Select-Object -ExpandProperty UserAgent | Should Match 'WindowsPowerShell'
        }
        It "returns 'Bye' when sending /end" {
            Invoke-RestMethod -Uri http://localhost/end | Should Match 'Bye'  
        }
    }
    Context "Stopping" {
        # Wait a sec for the process to stopping
        Start-Sleep -Seconds 5
        It "Remove firewall rule when stopping" {
            $null = Get-NetFirewallRule -PolicyStore ActiveStore -DisplayName "Allow PS TestWS Port*" | Should throw
        }
        It "removes the listening tcp connection" {
            Get-NetTCPConnection -State Listen | Where-Object LocalPort -eq 80  | Should Be $null
        }
    }
}