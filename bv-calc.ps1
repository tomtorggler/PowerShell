
$path = Join-Path $HOME -ChildPath 'OneDrive/_BV/Experts Inside BV/Q*/Sales Invoice'
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
} | Group-Object Customer | Select-Object Name,@{
    n='sum'
    e={($_.group.value | Measure-Object -sum).Sum}
}

# | Export-Excel -TableName T1 -PivotTableName p1 -PivotColumns Customer -PivotRows Invoice


