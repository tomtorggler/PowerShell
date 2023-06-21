
function Get-InvoiceDetail {
    param(
        $year = [datetime]::UtcNow.Year,
        $quarter = "*"
    )
    process {
        $path = Join-Path $HOME -ChildPath "OneDrive/_BV/Experts Inside BV/$year/Q$quarter/Sales Invoice"
        Get-ChildItem $path -Filter *.xlsx -Recurse | ForEach-Object { 
            $n = $_.basename.Split('-')[0]
            $e = Import-Excel -Path $_.fullname  -NoHeader
            $c = $e | Where-Object p8 -eq 'Due Upon Receipt' | Select-Object -expand p1
            $t = $e | Where-Object p6 -eq total | Select-Object -expand p8
            [pscustomobject]@{
                Invoice = $n
                Customer = $c
                Value = $t
            }  
        }
    }
}

Get-InvoiceDetail


Get-InvoiceDetail | Group-Object Customer | Select-Object @{
    n="Invoice"
    e={"SUBTOTAL"}
},@{
    n='Customer'
    e={$_.Name}
},@{
    n='Value'
    e={($_.group.value | Measure-Object -sum).Sum}
}

