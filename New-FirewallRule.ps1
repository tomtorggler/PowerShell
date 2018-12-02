function New-FirewallRule {
    Param(
        [string]$Name,
        [int]$Port,
        [string]$Protocol
    )
    $params = @{
        DisplayName = $Name;
        Action = 'Allow';
        Description = "$Name on $Protocol/$Port";
        Enabled = 1;
        Profile = 'Any';
        Protocol = $Protocol;
        PolicyStore = 'PersistentStore';
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

#New-FirewallRule -Port 6060 -Name "Allow SMTP"