<#PSScriptInfo
.VERSION 1.0.1
.GUID f92f5ec3-48a9-45ee-aee7-372fdb0e6e35
.AUTHOR @torggler
.PROJECTURI https://ntsystems.it/PowerShell/start-testwebserver/
#>

<#
.SYNOPSIS
    Webserver for load balancer testing.
.DESCRIPTION
    Start a web listener that listens on a specified port and simply answers to any request, returning JSON object containing the request.
    Requires administrative rights to create the listener. 
.EXAMPLE
    .\Start-TestWebServer -Port 8001

    Start the test WebServer on port 8001.
.EXAMPLE
    .\Start-TestWebServer -Port 80 -CreateFirewallRule
    Invoke-RestMethod -Uri http://localhost | Select-Object UserAgent

    Start the test WebServer on port 80 and create a Firewall Rule to allow traffic to the specified port.
    The Invoke-RestMethod cmdlet is used to send a request to the listener and parse the output.
.INPUTS
    None.
.OUTPUTS
    None.
.LINK
    https://ntsystems.it/PowerShell/start-testwebserver/
#>

#Requires -RunAsAdministrator

[CmdletBinding(HelpUri = 'https://ntsystems.it/PowerShell/start-testwebserver/')]
Param(
    # Specify a TCP port number for the HTTP listener to use. Defaults to 8000.
    [Parameter(Position=0)]
    [ValidateRange(1,65535)]
    [int] 
    $Port = 8000,

    # Use this switch to automatically create a Windows Firewall rule to allow incoming connections on the specified port.
    [switch]
    $CreateFirewallRule
)

#region Supporting Functions

function Write-Response {
    Param(
        $ResponseObject,
        $ContentType = 'application/json',
        $StatusCode = 200,
        $Message
    ) 
    $ResponseObject.ContentType = $ContentType
    $ResponseObject.StatusCode = $StatusCode
    [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $ResponseObject.ContentLength64 = $buffer.length
    $output = $ResponseObject.OutputStream
    $output.Write($buffer, 0, $buffer.length)
    $output.Close()
}

function New-FirewallRule {
    Param($Port)
    $params = @{
        DisplayName = "Allow PS TestWS Port $Port";
        Action = 'Allow';
        Description ="Allow PowerShell Test Web Server on Port $Port";
        Enabled = 1;
        Profile = 'Any';
        Protocol = 'TCP';
        PolicyStore = 'ActiveStore';
        LocalPort=$Port;
        ErrorAction = 'Stop';
    }
    try {
         $null = New-NetFirewallRule @params
    }
    catch {
        Write-Warning "Could not create firewall rule: $_"
    }
}

function Remove-FirewallRule {
    Param($Port)
    try {
        Remove-NetFirewallRule -DisplayName "Allow PS TestWS Port $Port" -PolicyStore ActiveStore -ErrorAction Stop    
    }
    catch {
        Write-Warning "Could not remove firewall rule: $_"
    }
}

#endregion

#region WebServer

if ($CreateFirewallRule) {
    Write-Verbose "Creating Firewall Rule"
    New-FirewallRule($Port)
}

# Define listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")

# Start listener 
try {
    $listener.Start() 
    Write-Verbose "Listening on port: $port - End with /end"
    while ($true) {   
        # blocks until request is received
        $context = $listener.GetContext() 
        $request = $context.Request
        $response = $context.Response

        if ($request.Url -match '/end$') { 
            Write-Verbose "Received END request: $($request.Url) from UA $($request.UserAgent)"     
            Write-Response -ResponseObject $response -ContentType 'text/plain' -Message 'Bye'
            Remove-Variable request, response
            break
        }
        
        # The default behaviour is to simply return the request as JSON object  
        else {
            Write-Verbose "Received URL: $($request.Url) from UA: $($request.UserAgent)"
            Write-Response -ResponseObject $response -Message ($request | ConvertTo-Json)          
        }
    }
}
catch { 
    Write-Warning -Message $_
}
finally { 
    $listener.Stop()

    if($CreateFirewallRule) {
        Write-Verbose "Remove Firewall Rule"
        Remove-FirewallRule($Port)
    }
}

#endregion
