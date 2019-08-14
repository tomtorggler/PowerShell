
function New-GHFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Owner,
        
        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$Token,     
        
        [Parameter(Mandatory)]
        [string]$Content,

        [string]$Message
    )
    $Headers = @{
        Authorization = "token $Token"
        Accept = "application/vnd.github.v3+json"
    }        
    $Body = @{
        message = $Message
        content = $(ConvertTo-Base64 -String $Content)
    }
    $uri = "https://api.github.com/repos/{0}/{1}/contents/{2}" -f $Owner,$Repository,$Path
    Invoke-RestMethod -Method PUT -Uri $Uri -Headers $Headers -Body ($Body | ConvertTo-Json)
}


function Get-GHFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Owner,
        
        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [string]$Token
    )
    $Headers = @{
        Authorization = "token $Token"
        Accept = "application/vnd.github.v3+json"
    }        
    $uri = "https://api.github.com/repos/{0}/{1}/contents/{2}" -f $Owner,$Repository,$Path
    Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
}


function Remove-GHFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ParameterSetName="Path",Mandatory)]
        [string]$Path,

        [Parameter(ParameterSetName="Path",Mandatory)]
        [string]$Owner,
        
        [Parameter(ParameterSetName="Path",Mandatory)]
        [string]$Repository,

        [Parameter(ParameterSetName="Path",Mandatory)]
        [string]$Sha,

        [Parameter(ParameterSetName="Path")]
        [string]$Message,

        [Parameter(Mandatory)]
        [string]$Token,

        [Parameter(ParameterSetName="IO",ValueFromPipeline)]
        $InputObject
    )

    if($InputObject){
        $uri = $InputObject.url
        $Sha = $InputObject.sha
        $Message = "Deletes item $uri"
    } else {
        $uri = "https://api.github.com/repos/{0}/{1}/contents/{2}" -f $Owner,$Repository,$Path
    }

    $Headers = @{
        Authorization = "token $Token"
        Accept = "application/vnd.github.v3+json"
    }        
    $Body = @{
        message = $Message
        sha = $Sha
    }
    if($PSCmdlet.ShouldProcess($uri,"Remove item")){
        Write-Verbose -Message ($Body | ConvertTo-Json -Compress)
        Invoke-RestMethod -Method Delete -Uri $Uri -Headers $Headers -Body ($Body | ConvertTo-Json)
    }
}

