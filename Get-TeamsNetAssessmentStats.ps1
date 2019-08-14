function Get-Jitter {
    [CmdletBinding()]
    param (
        $Filename
    )
    process {
        (Select-String -Path $Filename -Pattern "jitter:\s+(\d+\.\d+)\sms").matches.groups.where{$_.name -eq 1}.value | Measure-Object -Minimum -Maximum -Average    
    }
}

function Get-PLoss {
    [CmdletBinding()]
    param (
        $Filename
    )
    process {
        (Select-String -Path $Filename -Pattern "loss\srate:\s+(\d+\.\d+)").matches.groups.where{$_.name -eq 1}.value | ForEach-Object {[double]$_*100} | Measure-Object -Minimum -Maximum -Average    
    }
}


function Get-Latency {
    [CmdletBinding()]
    param (
        $Filename
    )
    process {
        (Select-String -Path $Filename -Pattern "latency:\s+(\d+(\.\d+)?)").matches.groups.where{$_.name -eq 1}.value | Measure-Object -Minimum -Maximum -Average    
    }
}

function Get-TeamsNetAssessmentStats {
    [CmdletBinding()]
    param (
        $Filename
    )
    process {
        Write-Information "Packet Loss" -InformationAction Continue
        Get-PLoss -Filename $Filename
        Write-Information "Jitter" -InformationAction Continue
        Get-Jitter -Filename $Filename
        Write-Information "Latency" -InformationAction Continue
        Get-Latency -Filename $Filename
    }
    
}

#Get-TeamsNetAssessmentStats -Filename "C:\Users\thomas.torggler\Experts Inside GmbH\DT Swiss - Netzwerk Assessment\Biel - LAN\TeamsSkypeStatsDetail.txt"

Get-TeamsNetAssessmentStats -Filename "C:\Users\thomas.torggler\Experts Inside GmbH\unisg - Network Assessment\StGallen - WIFI\TeamsSkypeStatsDetail.txt"

