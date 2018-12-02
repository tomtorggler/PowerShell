
function Get-FindPeopleResponse {
    param(
        [System.IO.FileInfo]
        $Path
    )
    $lines = Select-String -Pattern "FindPeopleResponse" -Path $path | Select-Object -ExpandProperty Line
    foreach ($l in $lines) {
        ([regex]::Match($l,"<s:Envelope.*</s:Envelope>") | Select-Object -ExpandProperty Value) -as [xml]
    }
}


$n = $resp.Body.FindPeopleResponse.People.Persona.MobilePhones.PhoneNumberAttributedValue.Value.Number
$n += $resp.Body.FindPeopleResponse.People.Persona.HomePhones.PhoneNumberAttributedValue.Value.Number
$n += $resp.Body.FindPeopleResponse.People.Persona.BusinessPhoneNumbers.PhoneNumberAttributedValue.Value.Number

$n | select -Unique 


$j = start-job -ScriptBlock { 1..9999 }

do {
    if(-not(Get-UDDashboard)) {
        Start-UDDashboard -Dashboard $tempdb
    }
} while ($j.State -eq "Running")

