
function Get-AdObject {
    param($identity)
    if($identity -match "ou="){
        New-Object -TypeName psobject -Property (@{DistinguishedName = "OU=b,DC=example,DC=com"})
    }
    
}

function new-AdObject {
    New-Object -TypeName psobject -Property (@{DistinguishedName = "CN=a,OU=b,DC=example,DC=com"})
}

function New-CAP {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("EMEA-ES-ITV-ARB","EMEA-ES-ITV-URN")]
        [string]
        $Location,

        [Parameter(Mandatory)]
        [string]
        $DisplayName,

        [Parameter(Mandatory)]
        [ValidatePattern("^\+\d+")]
        [string]
        $DisplayNumber,

        [Parameter(Mandatory)]
        [string]
        $OU,

        [Parameter(Mandatory)]
        [int]
        $PIN,

        [Parameter()]
        [int]
        $ExtensionLength = 4
    )
    
    process {
        $e164 = $DisplayNumber -replace "\+","" -replace " ",""
        $Extension = $e164.Substring($e164.length -$ExtensionLength)
        $ContactName = ($Location -replace "^\w4","PHONE"),$e164 -join "-"
        $LineUri = "tel:+{0};ext={1}" -f $e164,$Extension
        $SipUri = "sip:{0}@{1}.example.com" -f $ContactName,($Location.ToLower() -split "-" | Select-Object -First 1)
        $ClientPolicy = $Location + "-CAP-STD"
        $DialPlan = "tag:{0}" -f $Location
        $VoicePolicy = $Location -replace "\w+$","International"

        $Pool = switch -Regex ($Location)  {
            "EMEA-ES" { "es-bar-sbs1.example.com" }
            "EMEA-DE" { "de-ber-sbs1.example.com" }
        }
                
        # learn how test-path works with ou
        if($ContactObject = Get-AdObject $ContactName -ErrorAction SilentlyContinue){
            Write-Verbose "Contact [$ContactName] found. Using existing object."
        } elseif($OU = Get-Adobject -Identity $ou -ErrorAction SilentlyContinue) {
            Write-Verbose "OU [$OU] exists"
            Write-Verbose "Contact [$ContactName] does not exist."

            if($PSCmdlet.ShouldProcess("Name [$ContactName]","Create Contact")){
                $ContactObject = New-AdObject -Type Contact -Path $OU -Name $ContactName -PassThru
                Write-Information "Created Contact: $($ContactObject.DistinguishedName)"
            }
             
        } else {
            Write-Warning "Contact [$ContactName] not found, OU [$OU] not found. End of story."
            continue
        }


        if($ContactObject){
            Write-Verbose "Created Contact, starting jobs"
        
            $InfoDict = @{
                DN = $ContactObject.DistinguishedName
                SipUri = $SipUri
                LineUri = $LineUri
                RegistrarPool = $Pool
                DisplayName = $DisplayName
                Pin = $Pin
                DialPlan = $DialPlan
                ClientPolicy = $ClientPolicy
                VoicePolicy = $VoicePolicy

            } 
            
            $InfoDict | ConvertTo-Json 

            if($PSCmdlet.ShouldProcess("dn [$($ContactObject.DistinguishedName)] pool [$pool] pin [$pin] cp [$ClientPolicy]","Create CAP")){

                Start-Job -ArgumentList $InfoDict -ScriptBlock {
                    param($Input)
                    New-CsCommonAreaPhone @Input
                    Grant-CsDialPlan -Identity $Input.SipAddress -PolicyName $Input.DialPlan
                    Grant-CsVoicePolicy -Identity $Input.SipAddress -PolicyName $Input.VoicePolicy
                    Grant-CsClientPolicy -Identity $Input.SipAddress -PolicyName $Input.ClienPolicy
                    Set-CsClientPin -Identity $Input.SipAddress -PolicyName $Input.Pin
                }
            }
        }
    }
}

function Get-CAP {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("EMEA-ES-ARB","EMEA-ES-URN")]
        [string]
        $Location
    )
    Get-CsCommonAreaPhone -Filter "DialPlan -eq $Location" | Select-Object -Property DisplayName,DisplayNumber,LineUri,SipAddress,DialPlan,VoicePolicy,ClienPolicy
}

#new-cap -Location EMEA-ES-ITV-ARB -DisplayName "itv arbizu test" -DisplayNumber "+34 123 456 789" -OU "ou=weur,dc=example,dc=com" -pin 123  -InformationAction Continue