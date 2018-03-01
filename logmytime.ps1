

function Get-LogMyTimeEntries {
    [CmdletBinding()]
    param (
        $Key = 'b4x4xrkjpy'
    )

    $apiResult = Invoke-LMTApiCall -Key $Key -Uri https://api.logmytime.de/V1/Api.svc/TimeEntries | Select-Object -ExpandProperty results

    foreach ($te in $apiResult) {
        $out = [ordered]@{
            'LastChange' = (Get-Date $te.LastChangeTime)
            'Client' = (Get-LogMyTimeProject -InputObject $te).Client
            'Project' = (Get-LogMyTimeProject -InputObject $te).Project
            'Comment' = $te.Comment
            'DurationString' = $te.DurationString
            'Billable' = $te.Billable
        }
        Write-Output (New-Object -TypeName psobject -Property $out) | Sort-Object -Property LastChange -Descending
    }
}


function Get-LogMyTimeProject {
    [CmdletBinding()]
    param (
        $InputObject
    )
    process {
        foreach ($project in $($InputObject.project.__deferred.uri)) {
            $p = Invoke-LMTApiCall -Uri $project
            $result = @{ 
                "Project" = $($p.Name)
                "Client" = (Get-LogMyTimeClient -InputObject $p)
            }
            Write-Output (New-Object -TypeName psobject -Property $result)
        }
    }
}

function Get-LogMyTimeClient {
    [CmdletBinding()]
    param (
        $InputObject
    )
    process {
        $cl = Invoke-LMTApiCall -Uri $($InputObject.client.__deferred.uri)
        $cl.Name
    }
}

function Invoke-LMTApiCall {
    [CmdletBinding()]
    param (
        $Uri,
        $Key = 'b4x4xrkjpy'
    )
    
    begin {
        $Headers = @{
            'X-LogMyTimeApiKey' = $key
            'User-Agent' = 'PowerShell'
            'accept' = 'application/json'
        }
    }
    
    process {
        Invoke-RestMethod -Method Get -Headers $Headers -Uri $Uri | Select-Object -ExpandProperty d
    }
    
    end {
    }
}