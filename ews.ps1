Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$EmailAccount = "tom@uclab.eu" 
$Password = "*"

<<<<<<< HEAD




=======
>>>>>>> 4bdf3504cbf9eb2829425581d2c9de7b7de890af
$EWS = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1) 
$EWS.Credentials = New-Object Net.NetworkCredential($EmailAccount, $Password)
$EWS.AutodiscoverUrl($EmailAccount,{$true}) 

$userid = [Microsoft.Exchange.WebServices.Data.ImpersonatedUserId]::new()
<<<<<<< HEAD
$userid.id = "__"
$userid.id = "__"
=======
$userid.id = "user1@uclab.eu"
>>>>>>> 4bdf3504cbf9eb2829425581d2c9de7b7de890af
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
