<#PSScriptInfo
.VERSION 0.9.2
.GUID f92f5ec3-48a9-45ee-aee7-372fdb0e6e35
.AUTHOR @torggler
.PROJECTURI http://www.ntsystems.it/
#>

<# 
.DESCRIPTION
    Start a web listener that listens on a specified port and simply answers to any request, returning the URL and User-Agent string.
#>

<#
.SYNOPSIS
    Webserver for load balancer testing.
.DESCRIPTION
    Start a web listener that listens on a specified port and simply answers to any request, returning the URL and User-Agent string.
.EXAMPLE
    .\Start-TestWebServer -Port 8001

    Start the test WebServer on port 8001.
.EXAMPLE
    .\Start-TestWebServer -Port 80 -Title "My Server" -CreateFirewallRule

    Start the test WebServer on port 8001 and create a Firewall Rule to allow traffic to the specified port.
.ROLE
    Requires administrative rights to create the listener. 
.LINK
    http://www.ntsystems.it/PowerShell/start-testwebserver/
#>

#Requires -RunAsAdministrator

[CmdletBinding(HelpUri = 'http://www.ntsystems.it/PowerShell/start-testwebserver/')]
Param
(
    # Specify a tcp port number for the HTTP listener to use
    [Parameter(Position=0)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,65535)]
    [int] 
    $Port=8000,

    # Specify title for the Website
    [Parameter(Position=1)]
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [string]
    $Title = "TestWebServer",

    [switch]
    $CreateFirewallRule
)

# supporting funtion to read the input stream 
function Receive-Stream {

param( [System.IO.Stream]$reader, $encoding = [System.Text.Encoding]::GetEncoding( $null ) )

    [string]$output = ""
    [byte[]]$buffer = new-object byte[] 4096
    [int]$total = [int]$count = 0
   
    do {
        $count = $reader.Read($buffer, 0, $buffer.Length)
        $output += $encoding.GetString($buffer, 0, $count)
    } while ($count -gt 0)
    $reader.Close()
    $output 
}

if ($CreateFirewallRule) {
    Write-Verbose "Creating Firewall Rule"
    $params = @{
        DisplayName = "Allow PS TestWS Port $Port";
        Action = "Allow";
        Description ="Allow PowerShell Test Web Server on Port $Port";
        Enabled = 1;
        Profile = "Any";
        Protocol = "TCP";
        PolicyStore = "ActiveStore";
        LocalPort=$Port
    }
    $null = New-NetFirewallRule @params

}

# Create listener and start server
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$port/")
$listener.Start()       

Write-Host -ForegroundColor Yellow "Listening on port: $port - End with /end"

while ($true) {   
    # blocks until request is received
    $context = $listener.GetContext() 
    $request = $context.Request
    $response = $context.Response

    if ($request.Url -match '/end$') { 
        Write-Verbose "Received END request: $($request.Url) from UA $($request.UserAgent)"    
            
        $response.ContentType = 'text/html'

        $UserHostName = $request.UserHostName.Split(':') | Select-Object -First 1

        $params = @{
            Title = "test";
            Body = "Request: $($request.Url) <br> UA: $($request.UserAgent)"
            PostContent = "<a href=`"http://$UserHostName/abcdef`">Abcdef</a> <br> <a href=`"http://$UserHostName/end`">End?</a>"
        }
        $message = ConvertTo-Html @params

        [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $buffer.length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.length)
        $output.Close()            
        
        Remove-Variable request, response
        
        $listener.Stop()
    
        break
    }
    
    else {
        Write-Verbose "Received URL: $($request.Url) from UA: $($request.UserAgent)" 
            
        $response.ContentType = 'text/html'

        $UserHostName = $request.UserHostName.Split(':') | Select-Object -First 1

        $params = @{
            Title = "test";
            Body = "Request: $($request.Url) <br> UA: $($request.UserAgent)"
            PostContent = "<a href=`"http://$UserHostName/abcdef`">Abcdef</a> <br> <a href=`"http://$UserHostName/end`">End?</a>"
        }
        $message = ConvertTo-Html @params
        
        [byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $buffer.length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.length)
        $output.Close()            
    }
     
}
$listener.Stop()

if($CreateFirewallRule) {
    Write-Verbose "Remove Firewall Rule"
    Remove-NetFirewallRule -DisplayName "Allow PS TestWS Port $Port" -PolicyStore ActiveStore
}
