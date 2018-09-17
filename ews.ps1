Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$EmailAccount = "tom@uclab.eu" 
$Password = "*"
$EWS = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1) 
$EWS.Credentials = New-Object Net.NetworkCredential($EmailAccount, $Password)
$EWS.AutodiscoverUrl($EmailAccount,{$true}) 

$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($ews,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox) 
$Contacts = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($ews,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Contacts) 

$ContactItems = $Contacts.FindItems(50)
$ContactItems | %{$_.Load()}

foreach($c in $ContactItems){
    New-Object -TypeName psobject -Property ([ordered]@{
        DisplayName = $c.DisplayName
        BusinessPhone = $c.PhoneNumbers[[Microsoft.Exchange.WebServices.Data.PhoneNumberKey]::BusinessPhone]
        MobilePhone = $c.PhoneNumbers[[Microsoft.Exchange.WebServices.Data.PhoneNumberKey]::MobilePhone]
        HomePhone = $c.PhoneNumbers[[Microsoft.Exchange.WebServices.Data.PhoneNumberKey]::HomePhone]    
    })
}

				