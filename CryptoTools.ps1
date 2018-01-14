function Convert-BchAddress {
    <#
    .SYNOPSIS
        Converts Bitcoin Cash Address formats. 
    .DESCRIPTION
        This function uses https://cashaddr.bitcoincash.org to convert Bitcoin Cash address formats. It supports legacy and bitcoincash: address formats.
        The outout is a custom object containing all address formats and links to block explorers to for convenience. 
    .EXAMPLE
        PS C:\> Convert-BchAddress -Address "1BppmEwfuWCB3mbGqah2YuQZEZQGK3MfWc"
        
        This example converts a legacy address to the new bitcoincash format.
    .EXAMPLE
        PS C:\> Convert-BchAddress -Address "bitcoincash:qpmtetdtqpy5yhflnmmv8s35gkqfdnfdtywdqvue4p"
        
        This example converts a new address to the legacy format.
    .INPUTS
        [string]
    .OUTPUTS
        [PSCustomObject]
    .NOTES
        More information: https://www.bitcoinabc.org/cashaddr 
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        $Address
    )
    $uri = "https://cashaddr.bitcoincash.org/convert?address=$Address"
    try {
        $out = Invoke-RestMethod -Uri $uri -ErrorAction Stop
    } catch {
        Write-Warning "Could not connect."
    }
    $out | Add-Member -MemberType NoteProperty -Name "Blockchair" -Value "https://blockchair.com/bitcoin-cash/address/$($out.cashaddr.replace(":","%3A"))"
    $out | Add-Member -MemberType NoteProperty -Name "Blockdozer" -Value "https://blockdozer.com/insight/address/$($out.cashaddr.replace(":","%3A"))"
    Write-Output $out
}



