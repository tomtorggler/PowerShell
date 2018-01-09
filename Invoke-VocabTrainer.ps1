
[CmdletBinding()]
param (
    [System.IO.FileInfo]
    $Path = "C:\Users\Thomas\OneDrive\Audio\vocab\vocab_noun.csv",
    $Count,
    [ValidateSet("de","it","en","us")]
    $SourceLanguage = "de",
    [ValidateSet("de","it","en","us")]
    $DestinationLanguage = "es"
)


try {
    [System.Collections.ArrayList]$csvImport = Import-Csv $Path -Encoding UTF7 -ErrorAction Stop
}
catch {
    Write-Warning "Could not import CSV file $Path"
}

# Randomize the list
$csvImport = Get-Random -InputObject $csvImport -Count $csvImport.Count


foreach ($item in $csvImport) {

    switch ($SourceLanguage) {
        "de" { 
            $input = Read-Host -Prompt "`nWas heißt $($item.deutsch) in $DestinationLanguage"
        }
        "en" {
            $input = Read-Host -Prompt "`nWhat's $($item.english) in $DestinationLanguage"
        }
        "es" {
            $input = Read-Host -Prompt "`nQué es $($item.spanish) in $DestinationLanguage"
        }
        "it" {
            $input = Read-Host -Prompt "`nCom'è $($item.italiano) in $DestinationLanguage"
        }
    }

}



