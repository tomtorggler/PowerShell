

function Get-QoSPolicy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet("User","Computer","All")]
        $Type = "Computer"
    )

    switch ($Type) {
        'User' { 
            $QoSPath = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\QoS"
         }
        'Computer' {  
            $QoSPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
        }
        'All' { 
            $QoSPath = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS","HKCU:\SOFTWARE\Policies\Microsoft\Windows\QoS")
        }
    }

    foreach($path in $QoSPath) {
        $QoS = Get-Item -Path $path
        Write-Verbose "Found $($Qos.SubkeyCount) Policies in $($QoS.PSDrive)."
        if($QoS.SubKeyCount -ne 0){
            Get-ChildItem $path | ForEach-Object {
                
                New-Object -TypeName psobject -Property ([ordered]@{
                    Drive = $_.PSDrive
                    Name = $_.PsChildName
                    Properties = Get-ItemProperty -Path $_.PsPath | Select-Object -Property * -ExcludeProperty ps*
                })
            }
        }     
    }
}