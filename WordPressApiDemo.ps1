# Playing around with the WordPress JSON API
function Get-WPPosts {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )
    process {
        $RequestUrl = $url + "/wp-json/wp/v2/posts"
        try {
            Write-Verbose "Intenando coneccion a $RequestUrl"
            Invoke-RestMethod -Uri $RequestUrl -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo connectar: $_"
        }
    }
}

function Search-WPPosts {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Url,
        [ValidateNotNullOrEmpty()]
        [string]$PalabraClave
    )
    process {
        $RequestUrl = $url + "/wp-json/wp/v2/posts?search=$PalabraClave"
        try {
            Write-Verbose "Intenando coneccion a $RequestUrl"
            $Resultado = Invoke-RestMethod -Uri $RequestUrl -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo connectar: $_"
            break
        }
        if(-not($Resultado)) {
            Write-Warning "No se econtró ninguna entrada con $PalabraClave"
        } 
        Write-Output $Resultado
    }
}

function Get-WPComments {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )
    process {
        $RequestUrl = $url + "/wp-json/wp/v2/comments"
        try {
            Write-Verbose "Intenando coneccion a $RequestUrl"
            Invoke-RestMethod -Uri $RequestUrl -ErrorAction Stop
        } catch {
            Write-Warning "No se pudo connectar: $_"
        }
    }
}

