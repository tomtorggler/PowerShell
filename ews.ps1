Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$EmailAccount = "tom@uclab.eu" 
$Password = "*"





$EWS = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1) 
$EWS.Credentials = New-Object Net.NetworkCredential($EmailAccount, $Password)
$EWS.AutodiscoverUrl($EmailAccount,{$true}) 

$userid = [Microsoft.Exchange.WebServices.Data.ImpersonatedUserId]::new()
$userid.id = "__"
$userid.id = "__"
$ews.ImpersonatedUserId = $userid

$Calendar = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($ews,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Calendar) 

$appointment = New-Object Microsoft.Exchange.WebServices.Data.Appointment -ArgumentList $EWS
$appointment.Subject = "EWS Test"
$appointment.Body = "EWS Test"
$appointment.Start = Get-Date (Get-DAte).AddHours(1)
$appointment.End = Get-Date (Get-DAte).AddHours(2)
$appointment.IsReminderSet = $true
$appointment.LegacyFreeBusyStatus = [Microsoft.Exchange.WebServices.Data.LegacyFreeBusyStatus]::Free
$appointment.Location = "Location"
$appointment.Save([Microsoft.Exchange.WebServices.Data.SendInvitationsMode]::SendToNone)
$appointment.id.ChangeKey
$Calendar.FindItems(2).id.changekey
